function mapKeyboardId(key: String): String {
  switch (key) {
    case '0':
      return 'Zero';

    case '1':
      return 'One';

    case '2':
      return 'Two';

    case '3':
      return 'Three';

    case '4':
      return 'Four';

    case '5':
      return 'Five';

    case '6':
      return 'Six';

    case '7':
      return 'Seven';

    case '8':
      return 'Eight';

    case '9':
      return 'Nine';

    case '!':
      return 'ExclamationMark';

    case '"':
      return 'DoubleQuote';

    case '#':
      return 'Hash';

    case '$':
      return 'Dollar';

    case '%':
      return 'Percent';

    case '&':
      return 'Ampersand';

    case '\'':
      return 'SingleQuote';

    case '(':
      return 'LeftParenthesis';

    case ')':
      return 'RightParenthesis';

    case '*':
      return 'Asterisk';

    case '+':
      return 'Plus';

    case ',':
      return 'Comma';

    case '-':
      return 'Minus';

    case '.':
      return 'Period';

    case '/':
      return 'Slash';

    case ':':
      return 'Colon';

    case ';':
      return 'Semicolon';

    case '<':
      return 'LessThan';

    case '=':
      return 'Equal';

    case '>':
      return 'GreaterThan';

    case '?':
      return 'QuestionMark';

    case '@':
      return 'At';

    case '[':
      return 'LeftBracket';

    case ']':
      return 'RightBracket';

    case '^':
      return 'Caret';

    case '_':
      return 'Underscore';

    case '`':
      return 'Backtick';

    case '\\':
      return 'Backslash';

    case 'kp.':
      return 'KpPeriod';

    case 'kp/':
      return 'KpDivision';

    case 'kp*':
      return 'KpAsterisk';

    case 'kp+':
      return 'KpPlus';

    case 'kp-':
      return 'KpMinus';

    case 'kp=':
      return 'KpEqual';

    case 'nonus#':
      return 'NonUSHash';

    default:
      return key;
  }
}

function mapKeyboardValue(value: String): String {
  if (value == '\'' || value == '\\' || value == '"') {
    return '\\${value}';
  }

  return value;
}
