<?php
require 'koneksi.php';

header('Content-Type: application/json');

// Mengambil parameter filter dari URL
$status_filter_text = isset($_GET['status']) ? $_GET['status'] : 'All';
$category_filter = isset($_GET['category']) ? $_GET['category'] : 'All';

die(json_encode(['debug_status_diterima' => $status_filter_text, 'debug_kategori_diterima' => $category_filter]));

// Mapping teks status dari Flutter ke ID status di database
$status_map = [
    'New' => 0,
    'Waiting Reply' => 1,
    'Replied' => 2,
    'Resolved' => 3,
    'In Progress' => 4,
    'On Hold' => 5,
];

// Query dasar
$sql = "SELECT 
            t.trackid, t.subject, t.status, t.priority, t.lastchange,
            c.name AS category_name
        FROM `hesk_tickets` AS t
        LEFT JOIN `hesk_categories` AS c ON t.category = c.id";

$conditions = [];
$params = [];
$types = '';

// Logika untuk filter status
if (array_key_exists($status_filter_text, $status_map)) {
    $conditions[] = "t.status = ?";
    $params[] = $status_map[$status_filter_text];
    $types .= 'i';
}
// Jika 'All', tidak ada filter status yang ditambahkan

// Logika untuk filter kategori
if ($category_filter != 'All') {
    $conditions[] = "t.category = ?";
    $params[] = $category_filter;
    $types .= 'i';
}

// Gabungkan kondisi filter
if (!empty($conditions)) {
    $sql .= " WHERE " . implode(" AND ", $conditions);
}

$sql .= " ORDER BY t.lastchange DESC";

// Eksekusi query dengan aman
$stmt = mysqli_prepare($conn, $sql);
if (!empty($params)) {
    mysqli_stmt_bind_param($stmt, $types, ...$params);
}
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

// Proses hasil query
$tickets = [];
if ($result) {
    while ($row = mysqli_fetch_assoc($result)) {
        // Mapping nomor status ke teks Bahasa Inggris untuk dikirim ke Flutter
        $status_text = array_search((int)$row['status'], $status_map) ?: 'Unknown';

        $priority_text = match ((int)$row['priority']) {
            0 => 'Critical', 1 => 'High', 2 => 'Medium', 3 => 'Low',
            default => 'Unknown',
        };

        $tickets[] = [
            'id' => $row['trackid'],
            'title' => $row['subject'],
            'category' => $row['category_name'],
            'status' => $status_text,
            'division' => 'Umum',
            'priority' => $priority_text,
            'lastUpdate' => date("d M Y, H:i", strtotime($row['lastchange']))
        ];
    }
}

mysqli_stmt_close($stmt);
mysqli_close($conn);

echo json_encode($tickets);
?>