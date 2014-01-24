var spawn = require('child_process').spawn,
    ls    = spawn("coffee", ["-e", "require('./server').startServer(3333, 'public', -> console.log('done'))"]);

ls.stdout.on('data', function (data) {
  console.log('stdout: ' + data);
});

ls.stderr.on('data', function (data) {
  console.log('stderr: ' + data);
});

ls.on('close', function (code) {
  console.log('child process exited with code ' + code);
});

// console.log("dadasd")