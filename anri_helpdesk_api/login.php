<?php
// Sertakan file koneksi database
require 'koneksi.php';

// Set header sebagai JSON karena kita akan mengirim respons dalam format JSON
header('Content-Type: application/json');

// Buat array untuk respons
$response = array();

// Menerima data JSON yang dikirim dari Flutter
$data = json_decode(file_get_contents("php://input"));

// Pastikan data yang dibutuhkan ada
if (isset($data->username) && isset($data->password)) {
    $username = mysqli_real_escape_string($conn, $data->username);
    $password = $data->password;

    // --- PENTING: Menggunakan Prepared Statements untuk Keamanan (Mencegah SQL Injection) ---
    $sql = "SELECT id, `user`, `pass`, `name`, `email` FROM `hesk_users` WHERE `user` = ?";
    
    // Siapkan statement
    $stmt = mysqli_prepare($conn, $sql);
    
    // Bind parameter
    mysqli_stmt_bind_param($stmt, "s", $username);
    
    // Eksekusi statement
    mysqli_stmt_execute($stmt);
    
    // Dapatkan hasilnya
    $result = mysqli_stmt_get_result($stmt);

    if (mysqli_num_rows($result) > 0) {
        // Jika user ditemukan, ambil datanya
        $row = mysqli_fetch_assoc($result);
        
        // Verifikasi password yang diinput dengan hash di database
        // Ingat, database Anda menggunakan hashing BCrypt
        if (password_verify($password, $row['pass'])) {
            // Jika password cocok
            $response['success'] = true;
            $response['message'] = "Login berhasil!";
            $response['data'] = array(
                'id' => $row['id'],
                'name' => $row['name'],
                'email' => $row['email'],
                'username' => $row['user']
            );
        } else {
            // Jika password salah
            $response['success'] = false;
            $response['message'] = "Username atau password salah.";
        }
    } else {
        // Jika user tidak ditemukan
        $response['success'] = false;
        $response['message'] = "Username tidak ditemukan.";
    }
    
    // Tutup statement
    mysqli_stmt_close($stmt);

} else {
    // Jika data tidak lengkap
    $response['success'] = false;
    $response['message'] = "Data tidak lengkap.";
}

// Tutup koneksi
mysqli_close($conn);

// Kembalikan respons dalam format JSON
echo json_encode($response);
?>