from colored import fg, bg, attr

def print_success(out: str):
  color = fg('6')
  res = attr('reset')
  print(color + out + res)


def print_error(out: str):
  color = fg('1')
  res = attr('bold')+attr('reset')
  print(color + out + res)


def print_script_stdout(out: str):
  color = fg('2')
  res = attr('reset')
  print(color + out + res)


def print_script_stderr(out: str):
  color = fg('8')+bg('235')
  res = attr('bold')+attr('reset')
  print(color + out + res)
