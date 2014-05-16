// Meteor app main helper. `require` this file in custom mirror `main`
// scripts to finish booting normally after any custom initialization.
var path = require('path');
process.argv.splice(2, 0, 'program.json');
process.chdir(path.join(process.cwd(), '.meteor', 'local', 'build', 'programs', 'server'));
require(path.join(process.cwd(), 'boot.js'));
