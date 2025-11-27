const { sql, poolPromise } = require('./db');

const getAllDepartments = async () => {
  try {
    const pool = await poolPromise;
    const result = await pool
      .request()
      .query('SELECT id, name, description FROM departments ORDER BY name ASC');
    return result.recordset;
  } catch (err) {
    console.log(err);
    return [];
  }
};

const getDepartmentById = async (id) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('id', sql.Int, id);
    const result = await request.query('SELECT id, name, description FROM departments WHERE id = @id');
    return result.recordset[0] || null;
  } catch (err) {
    console.log(err);
    return null;
  }
};

const addDepartment = async (department) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('name', sql.NVarChar, department.name);
    request.input('description', sql.NVarChar, department.description ?? null);
    const result = await request.query(
      `INSERT INTO departments (name, description)
       OUTPUT INSERTED.id,
              INSERTED.name,
              INSERTED.description
       VALUES (@name, @description)`,
    );
    return result.recordset[0];
  } catch (err) {
    console.log(err);
    return null;
  }
};

const updateDepartment = async (id, department) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('id', sql.Int, id);
    request.input('name', sql.NVarChar, department.name);
    request.input('description', sql.NVarChar, department.description ?? null);
    const result = await request.query(
      `UPDATE departments
       SET name = @name,
           description = @description
       OUTPUT INSERTED.id,
              INSERTED.name,
              INSERTED.description
       WHERE id = @id`,
    );
    return result.recordset[0] || null;
  } catch (err) {
    console.log(err);
    return null;
  }
};

const deleteDepartment = async (id) => {
  try {
    const pool = await poolPromise;
    const request = pool.request();
    request.input('id', sql.Int, id);
    const result = await request.query('DELETE FROM departments WHERE id = @id');
    return result.rowsAffected[0] > 0;
  } catch (err) {
    console.log(err);
    return false;
  }
};

module.exports = {
  getAllDepartments,
  getDepartmentById,
  addDepartment,
  updateDepartment,
  deleteDepartment,
};

