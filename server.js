const express = require('express');
const mysql = require('mysql2');
const cors = require('cors');

const app = express();
app.use(express.json());
app.use(cors());

// 1. Connect to Database
const db = mysql.createConnection({
    host: 'localhost',
    user: 'root',
    password: 'PunitH@767688', // <--- ⚠️ PUT YOUR REAL PASSWORD HERE
    database: 'expiry_plans',
    dateStrings: true // <--- 🟢 CRITICAL FIX: Keeps dates exact (no -1 day glitch)
});

db.connect((err) => {
    if (err) console.error('❌ Database connection failed:', err);
    else console.log('✅ Connected to MySQL Database!');
    
    // Create Tables if they don't exist
    db.query(`CREATE TABLE IF NOT EXISTS app_users (
        id INT AUTO_INCREMENT PRIMARY KEY,
        fullName VARCHAR(255),
        email VARCHAR(255) UNIQUE,
        password VARCHAR(255)
    )`);

    db.query(`CREATE TABLE IF NOT EXISTS items (
        id INT AUTO_INCREMENT PRIMARY KEY,
        title VARCHAR(255),
        category VARCHAR(255),
        expiryDate DATE,
        userId INT
    )`);
});

// --- ROUTES ---

// UPDATE ITEM
app.put('/items/update/:id', (req, res) => {
    const itemId = req.params.id;
    const { title, category, expiryDate } = req.body;
    
    console.log(`📝 UPDATE Request for Item ${itemId}: ${title}, ${expiryDate}`);

    const sql = 'UPDATE items SET title = ?, category = ?, expiryDate = ? WHERE id = ?';
    db.query(sql, [title, category, expiryDate, itemId], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Item updated successfully' });
    });
});

// ADD ITEM
app.post('/items/add', (req, res) => {
    const { title, category, expiryDate, userId } = req.body;
    const sql = 'INSERT INTO items (title, category, expiryDate, userId) VALUES (?, ?, ?, ?)';
    db.query(sql, [title, category, expiryDate, userId || 1], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Item Added!' });
    });
});

// GET ITEMS
app.get('/items', (req, res) => {
    db.query('SELECT * FROM items ORDER BY expiryDate ASC', (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json(results);
    });
});

// DELETE ITEM
app.delete('/items/delete/:id', (req, res) => {
    const itemId = req.params.id;
    const sql = 'DELETE FROM items WHERE id = ?';
    db.query(sql, [itemId], (err, result) => {
        if (err) return res.status(500).json({ error: err.message });
        res.status(200).json({ message: 'Item deleted' });
    });
});

// REGISTER
app.post('/auth/register', (req, res) => {
    const { fullName, email, password } = req.body;
    const sql = 'INSERT INTO app_users (fullName, email, password) VALUES (?, ?, ?)';
    db.query(sql, [fullName, email, password], (err, result) => {
        if (err) return res.status(400).json({ error: 'Email likely already exists!' });
        res.status(200).json({ message: 'User Registered Successfully!' });
    });
});

// LOGIN
app.post('/auth/login', (req, res) => {
    const { email, password } = req.body;
    const sql = 'SELECT * FROM app_users WHERE email = ? AND password = ?';
    db.query(sql, [email, password], (err, results) => {
        if (err) return res.status(500).json({ error: err.message });
        if (results.length > 0) {
            res.status(200).json({ message: 'Login Successful', userId: results[0].id });
        } else {
            res.status(401).json({ error: 'Invalid email or password' });
        }
    });
});

// DELETE ACCOUNT
app.delete('/auth/delete/:userId', (req, res) => {
    const userId = req.params.userId;
    db.query('DELETE FROM items WHERE userId = ?', [userId], (err) => {
        if (err) return res.status(500).json({ error: err.message });
        db.query('DELETE FROM app_users WHERE id = ?', [userId], (err, result) => {
            if (err) return res.status(500).json({ error: err.message });
            res.status(200).json({ message: 'Account permanently deleted' });
        });
    });
});

// --- START SERVER ---
app.listen(8080, () => {
    console.log('🚀 Server running on port 8080');
});