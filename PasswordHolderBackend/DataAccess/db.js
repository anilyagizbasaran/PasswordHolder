const sql = require('mssql');
const config = {
  server: 'localhost', 
  database: 'PasswordHolder', 
  user: 'sa',
  password: '123', 
  options: {
    encrypt: false, 
    trustedConnection: false, 
  }
};
const poolPromise = new sql.ConnectionPool(config)
  .connect()
  .then(pool => {
    console.log('Connected to MSSQL')
    return pool
  })
  .catch(err => console.log('Database Connection Failed! Bad Config: ', err))
module.exports = {
  sql, poolPromise
}
