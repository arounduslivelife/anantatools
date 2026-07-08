import 'dart:io';

void main() async {
  String command = "Stop-Service -Name Spooler -Force; Remove-Item -Path '\$env:windir\\System32\\spool\\PRINTERS\\*.*' -Force -Recurse; Start-Service -Name Spooler";
  print("Command: \$command");
  var result = await Process.run('powershell', [
    'Start-Process',
    'powershell',
    '-Verb',
    'RunAs',
    '-WindowStyle',
    'Hidden',
    '-Wait',
    '-ArgumentList',
    '"-Command & { $command }"'
  ]);
  print("Exit code: \${result.exitCode}");
  print("Stdout: \${result.stdout}");
  print("Stderr: \${result.stderr}");
}
