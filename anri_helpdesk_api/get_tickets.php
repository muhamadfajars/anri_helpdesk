<?php
error_reporting(E_ALL);
ini_set('display_errors', 1);

require 'koneksi.php';
header('Content-Type: application/json');

$limit = 10;
$page = isset($_GET['page']) ? (int)$_GET['page'] : 1;
$offset = ($page - 1) * $limit;

$status_filter_text = isset($_GET['status']) ? trim($_GET['status']) : 'All';
$category_filter = isset($_GET['category']) ? trim($_GET['category']) : 'All';

$status_map = [
    'New' => 0, 'Waiting Reply' => 1, 'Replied' => 2,
    'Resolved' => 3, 'In Progress' => 4, 'On Hold' => 5,
];

// --- QUERY BARU UNTUK MENGAMBIL DATA TAMBAHAN ---
$sql = "SELECT 
            t.trackid, t.name AS requester_name, t.subject, t.status, t.priority,
            t.lastchange AS update_date,
            c.name AS category_name,
            owner_user.name AS assigned_to_name
        FROM `hesk_tickets` AS t
        LEFT JOIN `hesk_categories` AS c ON t.category = c.id
        LEFT JOIN `hesk_users` AS owner_user ON t.owner = owner_user.id";

$conditions = [];
$params = [];
$types = '';

if ($status_filter_text == 'All') {
    $conditions[] = "t.status != ?";
    $params[] = 3;
    $types .= 'i';
} elseif (array_key_exists($status_filter_text, $status_map)) {
    $conditions[] = "t.status = ?";
    $params[] = $status_map[$status_filter_text];
    $types .= 'i';
}

if ($category_filter != 'All') {
    $conditions[] = "t.category = ?";
    $params[] = $category_filter;
    $types .= 'i';
}

if (!empty($conditions)) {
    $sql .= " WHERE " . implode(" AND ", $conditions);
}

$sql .= " ORDER BY (t.priority = 0) DESC, t.lastchange DESC"; // Urutkan berdasarkan update terakhir

$sql .= " LIMIT ? OFFSET ?";
$params[] = $limit;
$params[] = $offset;
$types .= 'ii';

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

$tickets = [];
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        $status_text = array_search((int)$row['status'], $status_map, true) ?: 'Unknown';
        $priority_text = match ((int)$row['priority']) {
            0 => 'Critical', 1 => 'High', 2 => 'Medium', 3 => 'Low', default => 'Unknown',
        };

        $tickets[] = [
            'id' => $row['trackid'],
            'name' => $row['requester_name'], // Diubah dari 'name' agar lebih jelas
            'title' => $row['subject'],
            'category' => $row['category_name'],
            'status' => $status_text,
            'priority' => $priority_text,
            'lastUpdate' => $row['update_date'], // Menggunakan 'lastchange'
            // --- DATA BARU YANG DIKIRIM ---
            'assignedTo' => $row['assigned_to_name'] ?? 'Unassigned',
            'lastReplied' => $row['requester_name'], // Placeholder sesuai gambar
        ];
    }
}

mysqli_stmt_close($stmt);
mysqli_close($conn);

echo json_encode($tickets);
?>