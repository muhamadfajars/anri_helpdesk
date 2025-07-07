<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Methods: POST, GET, OPTIONS");
header("Access-Control-Allow-Headers: Content-Type, Authorization");
header('Content-Type: application/json; charset=utf-8');

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit();
}

error_reporting(E_ALL);
ini_set('display_errors', 1);

require 'auth_check.php';
require 'koneksi.php';

mysqli_set_charset($conn, 'utf8');

// --- MEKANISME PENGAMBILAN DATA YANG STABIL ---
$input_data = [];
// Coba baca dari $_POST terlebih dahulu (untuk kompatibilitas web)
if (!empty($_POST)) {
    $input_data = $_POST;
} else {
    // Jika $_POST kosong (masalah umum dengan Authorization Header), baca dari input mentah
    $raw_input = file_get_contents('php://input');
    parse_str($raw_input, $input_data);
}
// Mulai sekarang, gunakan $input_data, bukan $_POST

// Ambil data dari array $input_data yang sudah pasti terisi
$ticket_id = isset($input_data['ticket_id']) ? (int)$input_data['ticket_id'] : 0;
$message = isset($input_data['message']) ? trim($input_data['message']) : '';
$staff_id = isset($input_data['user_id']) ? (int)$input_data['user_id'] : (isset($input_data['staff_id']) ? (int)$input_data['staff_id'] : 0);
$new_status_text = isset($input_data['new_status']) ? trim($input_data['new_status']) : 'Replied';

// Validasi input
if (empty($ticket_id) || empty($message) || empty($staff_id)) {
    echo json_encode(['success' => false, 'message' => 'Data tidak lengkap. Pastikan ticket_id, message, dan user_id terkirim.']);
    exit();
}

// Peta status HESK
$status_map = [
    'New' => 0, 'Waiting Reply' => 1, 'Replied' => 2,
    'Resolved' => 3, 'In Progress' => 4, 'On Hold' => 5,
];
$new_status_id = $status_map[$new_status_text] ?? 2; // Default ke 'Replied' jika tidak valid

// Memulai transaction
mysqli_begin_transaction($conn);

try {
    // Ambil nama staf dari database berdasarkan ID
    $staff_name = 'Staff';
    $sql_get_name = "SELECT `name` FROM `hesk_users` WHERE `id` = ?";
    $stmt_get_name = mysqli_prepare($conn, $sql_get_name);
    mysqli_stmt_bind_param($stmt_get_name, 'i', $staff_id);
    mysqli_stmt_execute($stmt_get_name);
    $result_name = mysqli_stmt_get_result($stmt_get_name);
    if ($user_row = mysqli_fetch_assoc($result_name)) {
        $staff_name = $user_row['name'];
    }
    mysqli_stmt_close($stmt_get_name);

    // 1. Masukkan balasan
    $sql_reply = "INSERT INTO `hesk_replies` (`replyto`, `name`, `message`, `dt`, `staffid`) VALUES (?, ?, ?, NOW(), ?)";
    $stmt_reply = mysqli_prepare($conn, $sql_reply);
    mysqli_stmt_bind_param($stmt_reply, 'issi', $ticket_id, $staff_name, $message, $staff_id);
    if (mysqli_stmt_execute($stmt_reply) === false) {
        throw new mysqli_sql_exception("Gagal menyisipkan balasan: " . mysqli_stmt_error($stmt_reply));
    }
    mysqli_stmt_close($stmt_reply);

    // 2. Update tiket
    $sql_ticket = "UPDATE `hesk_tickets` SET `status`=?,`lastchange`=NOW(),`replies`=`replies`+1,`staffreplies`=`staffreplies`+1,`lastreplier`='1',`replierid`=? WHERE `id`=?";
    $stmt_ticket = mysqli_prepare($conn, $sql_ticket);
    mysqli_stmt_bind_param($stmt_ticket, 'iii', $new_status_id, $staff_id, $ticket_id);
    if (mysqli_stmt_execute($stmt_ticket) === false) {
        throw new mysqli_sql_exception("Gagal memperbarui tiket: " . mysqli_stmt_error($stmt_ticket));
    }
    mysqli_stmt_close($stmt_ticket);

    // Commit jika semua berhasil
    mysqli_commit($conn);
    echo json_encode(['success' => true, 'message' => 'Balasan berhasil dikirim.']);

} catch (mysqli_sql_exception $exception) {
    // Rollback jika ada error
    mysqli_rollback($conn);
    http_response_code(500);
    echo json_encode([
        'success' => false,
        'message' => 'Terjadi kesalahan pada database.',
        'error_details' => $exception->getMessage()
    ]);
}

mysqli_close($conn);
?>