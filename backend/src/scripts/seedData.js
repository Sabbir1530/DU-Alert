const { sequelize } = require('../config/db');
const User = require('../models/user.model');
const Department = require('../models/department.model');
const Role = require('../models/role.model');
const UserRole = require('../models/user_role.model');
const { hashData } = require('../utils/hash');

const departments = [
  'Computer Science and Engineering',
  'Electrical and Electronic Engineering',
  'Civil Engineering',
  'Mechanical Engineering',
  'Architecture'
];

const roles = ['student', 'proctor', 'admin', 'superadmin'];

const testUsers = [
  {
    full_name: 'Ahmed Ali',
    department: 'Computer Science and Engineering',
    registration_number: 'CSE-2020-001',
    university_email: 'ahmed.ali@du.edu.bd',
    phone_number: '01700000001',
    username: 'ahmedali',
    password: 'password123',
    is_verified: true,
    roleNames: ['student']
  },
  {
    full_name: 'Fatima Khan',
    department: 'Electrical and Electronic Engineering',
    registration_number: 'EEE-2020-002',
    university_email: 'fatima.khan@du.edu.bd',
    phone_number: '01700000002',
    username: 'fatimaKhan',
    password: 'password123',
    is_verified: true,
    roleNames: ['proctor']
  },
  {
    full_name: 'Dr. Mohammad Hassan',
    department: 'Computer Science and Engineering',
    registration_number: 'ADMIN-001',
    university_email: 'm.hassan@du.edu.bd',
    phone_number: '01700000003',
    username: 'mhassan',
    password: 'admin123',
    is_verified: true,
    roleNames: ['admin']
  },
  {
    full_name: 'Super Administrator',
    department: 'Computer Science and Engineering',
    registration_number: 'SUPERADMIN-001',
    university_email: 'superadmin@du.edu.bd',
    phone_number: '01700000004',
    username: 'superadmin',
    password: 'superadmin123',
    is_verified: true,
    roleNames: ['superadmin']
  }
];

const run = async () => {
  try {
    await sequelize.authenticate();
    console.log('DB authenticated');
    
    // Load models and associations
    require('../models');
    
    await sequelize.sync();
    console.log('Models synced');

    // Seed departments
    for (const name of departments) {
      await Department.findOrCreate({ where: { department_name: name } });
    }
    console.log('Departments seeded');

    // Seed roles
    for (const name of roles) {
      await Role.findOrCreate({ where: { name } });
    }
    console.log('Roles seeded');

    // Seed test users
    for (const userData of testUsers) {
      const { roleNames, ...userFields } = userData;
      
      // Hash password
      const hashedPassword = await hashData(userFields.password);
      
      // Create or find user
      const [user] = await User.findOrCreate({
        where: { registration_number: userFields.registration_number },
        defaults: { ...userFields, password: hashedPassword }
      });

      // Assign roles
      for (const roleName of roleNames) {
        const role = await Role.findOne({ where: { name: roleName } });
        if (role) {
          await UserRole.findOrCreate({
            where: { user_id: user.id, role_id: role.id }
          });
        }
      }
    }
    console.log('Test users seeded');
    console.log('\nTest user credentials:');
    console.log('1. Student - username: ahmedali, password: password123');
    console.log('2. Proctor - username: fatimaKhan, password: password123');
    console.log('3. Admin - username: mhassan, password: admin123');
    console.log('4. Superadmin - username: superadmin, password: superadmin123');
    
    process.exit(0);
  } catch (err) {
    console.error('Seed failed:', err);
    process.exit(1);
  }
};

run();
