<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require 'koneksi.php';
header('Content-Type: application/json');

// Mengambil parameter filter dari URL
$status_filter_text = isset($_GET['status']) ? trim($_GET['status']) : 'All';
$category_filter = isset($_GET['category']) ? trim($_GET['category']) : 'All';

// Mapping teks status ke ID status di database
$status_map = [
    'New' => 0, 'Waiting Reply' => 1, 'Replied' => 2,
    'Resolved' => 3, 'In Progress' => 4, 'On Hold' => 5,
];

// Query dasar, mengambil t.dt (waktu dibuat) dan t.name
$sql = "SELECT 
            t.trackid, t.name, t.subject, t.status, t.priority,
            t.dt AS creation_date, -- MENGAMBIL WAKTU DIBUAT
            c.name AS category_name
        FROM `hesk_tickets` AS t
        LEFT JOIN `hesk_categories` AS c ON t.category = c.id";

$conditions = [];
$params = [];
$types = '';

// --- LOGIKA FILTER STATUS BARU ---
if ($status_filter_text == 'All') {
    // Jika filter 'All', tampilkan semua KECUALI yang sudah 'Resolved'
    $conditions[] = "t.status != ?";
    $params[] = 3; // ID untuk 'Resolved'
    $types .= 'i';
} elseif (array_key_exists($status_filter_text, $status_map)) {
    // Jika filter status spesifik, cari berdasarkan ID status tersebut
    $conditions[] = "t.status = ?";
    $params[] = $status_map[$status_filter_text];
    $types .= 'i';
}

// Logika filter kategori
if ($category_filter != 'All') {
    $conditions[] = "t.category = ?";
    $params[] = $category_filter;
    $types .= 'i';
}

// Menggabungkan semua kondisi filter
if (!empty($conditions)) {
    $sql .= " WHERE " . implode(" AND ", $conditions);
}

// --- MENGURUTKAN BERDASARKAN WAKTU DIBUAT (TERBARU DI ATAS) ---
$sql .= " ORDER BY t.dt DESC";

// Eksekusi query dengan aman
$stmt = mysqli_prepare($conn, $sql);
if ($stmt === false) {
    echo json_encode(['success' => false, 'message' => 'Query SQL Error: ' . mysqli_error($conn)]);
    exit();
}
if (!empty($params)) {
    mysqli_stmt_bind_param($stmt, $types, ...$params);
}
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

// Proses hasil query
$tickets = [];
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $status_text = array_search((int)$row['status'], $status_map, true) ?: 'Unknown';
        $priority_text = match ((int)$row['priority']) {
            0 => 'Critical', 1 => 'High', 2 => 'Medium', 3 => 'Low', default => 'Unknown',
        };

        $tickets[] = [
            'id' => $row['trackid'],
            'name' => $row['name'],
            'title' => $row['subject'],
            'category' => $row['category_name'],
            'status' => $status_text,
            'division' => 'Umum',
            'priority' => $priority_text,
            'lastUpdate' => $row['creation_date'] // MENGIRIM WAKTU DIBUAT
        ];
    }
}

mysqli_stmt_close($stmt);
mysqli_close($conn);

echo json_encode($tickets);
?>