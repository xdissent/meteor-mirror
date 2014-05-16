
// Custom pre-meteor initialization
console.log('BAZ MAIN');

// Finish booting using the mirror main helper
require('../packages/mirror/main.js');

// Or do it yourself:
//
// var path = require('path');
// process.argv.splice(2, 0, 'program.json');
// process.chdir(path.join(process.cwd(), '.meteor', 'local', 'build', 'programs', 'server'));
// require(path.join(process.cwd(), 'boot.js'));
