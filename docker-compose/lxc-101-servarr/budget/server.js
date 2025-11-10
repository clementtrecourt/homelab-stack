// Fichier: server.js (version corrigée et complète)

const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const app = express();
const PORT = 2000;

app.use(express.static('public'));
app.use(express.json());

const dbPath = './data/database.db';
const db = new sqlite3.Database(dbPath, (err) => {
    if (err) {
        console.error("Erreur de connexion à la base de données :", err.message);
    }
    console.log('Connecté à la base de données SQLite.');
});

db.serialize(() => {
    // La colonne "is_hidden" est ajoutée ici
    db.run(`CREATE TABLE IF NOT EXISTS accounts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        is_hidden INTEGER DEFAULT 0
    )`);
    // Et aussi ici
    db.run(`CREATE TABLE IF NOT EXISTS transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        description TEXT NOT NULL,
        amount REAL NOT NULL,
        account_id INTEGER,
        is_hidden INTEGER DEFAULT 0,
        FOREIGN KEY (account_id) REFERENCES accounts(id) ON DELETE CASCADE
    )`);

    const checkQuery = "SELECT COUNT(*) as count FROM accounts";
    db.get(checkQuery, (err, row) => {
        if (err) {
            console.error("Erreur lors de la vérification des comptes :", err.message);
            return;
        }
        if (row.count === 0) {
            console.log("Base de données vide, création du compte par défaut...");
            db.run("INSERT INTO accounts (name) VALUES (?)", ["Compte Joint"], (err) => {
                if (err) console.error("Erreur lors de la création du compte par défaut :", err.message);
                else console.log("Compte 'Compte Joint' créé avec succès.");
            });
        }
    });
});


// GET /api/data : Obtenir toutes les données
app.get('/api/data', (req, res) => {
    db.all("SELECT * FROM accounts", [], (err, accounts) => {
        if (err) return res.status(500).json({ error: err.message });
        db.all("SELECT * FROM transactions", [], (err, transactions) => {
            if (err) return res.status(500).json({ error: err.message });
            const data = {
                accounts: accounts.map(acc => ({
                    ...acc,
                    transactions: transactions.filter(tx => tx.account_id === acc.id)
                }))
            };
            res.json(data);
        });
    });
});


// --- API POUR LES COMPTES ---
app.post('/api/accounts', (req, res) => {
    const { name } = req.body;
    if (!name || name.trim() === '') return res.status(400).json({ error: "Le nom du compte est requis." });
    const query = `INSERT INTO accounts (name) VALUES (?)`;
    db.run(query, [name.trim()], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id: this.lastID, name: name.trim(), transactions: [], is_hidden: 0 });
    });
});

app.put('/api/accounts/:id', (req, res) => {
    const { name } = req.body;
    if (!name) return res.status(400).json({ error: "Le nom est requis." });
    const query = `UPDATE accounts SET name = ? WHERE id = ?`;
    db.run(query, [name, req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: "Compte non trouvé."});
        res.json({ message: "Nom du compte mis à jour." });
    });
});

app.delete('/api/accounts/:id', (req, res) => {
    const query = `DELETE FROM accounts WHERE id = ?`;
    db.run(query, req.params.id, function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: "Compte non trouvé."});
        res.json({ message: "Compte supprimé avec succès." });
    });
});

// Route pour masquer/afficher un compte
app.put('/api/accounts/:id/toggle-hidden', (req, res) => {
    const { is_hidden } = req.body;
    if (is_hidden === undefined) return res.status(400).json({ error: "Le statut 'is_hidden' est requis." });
    const query = `UPDATE accounts SET is_hidden = ? WHERE id = ?`;
    db.run(query, [is_hidden, req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: "Compte non trouvé."});
        res.json({ message: "Visibilité du compte mise à jour." });
    });
});


// --- API POUR LES TRANSACTIONS ---
app.post('/api/transactions', (req, res) => {
    const { description, amount, accountId } = req.body;
    if (!description || amount === undefined || !accountId) return res.status(400).json({ error: "Données manquantes." });
    const query = `INSERT INTO transactions (description, amount, account_id) VALUES (?, ?, ?)`;
    db.run(query, [description, amount, accountId], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        res.status(201).json({ id: this.lastID, description, amount, account_id: accountId, is_hidden: 0 });
    });
});

app.put('/api/transactions/:id', (req, res) => {
    const { description, amount } = req.body;
    if (!description || amount === undefined) return res.status(400).json({ error: "Données manquantes." });
    const query = `UPDATE transactions SET description = ?, amount = ? WHERE id = ?`;
    db.run(query, [description, amount, req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: "Transaction non trouvée."});
        res.json({ message: "Transaction mise à jour." });
    });
});

app.delete('/api/transactions/:id', (req, res) => {
    const query = `DELETE FROM transactions WHERE id = ?`;
    db.run(query, req.params.id, function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: "Transaction non trouvée."});
        res.json({ message: "Transaction supprimée." });
    });
});

// Route pour masquer/afficher une transaction
app.put('/api/transactions/:id/toggle-hidden', (req, res) => {
    const { is_hidden } = req.body;
    if (is_hidden === undefined) return res.status(400).json({ error: "Le statut 'is_hidden' est requis." });
    const query = `UPDATE transactions SET is_hidden = ? WHERE id = ?`;
    db.run(query, [is_hidden, req.params.id], function(err) {
        if (err) return res.status(500).json({ error: err.message });
        if (this.changes === 0) return res.status(404).json({ error: "Transaction non trouvée."});
        res.json({ message: "Visibilité de la transaction mise à jour." });
    });
});

app.listen(PORT, () => {
    console.log(`Serveur démarré sur http://localhost:${PORT}`);
});
