
Package.describe({
  summary: 'Mirror mirror'
});

Npm.depends({
  'freeport': '1.0.2'
});

Package.on_use(function (api, where) {
  api.use(['underscore', 'coffeescript'], 'server');
  api.add_files('src/mirror.coffee', 'server');
  api.add_files('src/errors.coffee', 'server');
  api.add_files('src/main.coffee', 'server');
  api.export('Mirror', 'server');
});
