urlencode() {
  LC_ALL=C awk -- '
    BEGIN {
      for (i = 1; i <= 255; i++) hex[sprintf("%c", i)] = sprintf("%%%02X", i)
    }
    function urlencode(s,  c,i,r,l) {
      l = length(s)
      for (i = 1; i <= l; i++) {
        c = substr(s, i, 1)
        r = r "" (c ~ /^[-._~0-9a-zA-Z]$/ ? c : hex[c])
      }
      return r
    }
    BEGIN {
      for (i = 1; i < ARGC; i++)
        print urlencode(ARGV[i])
    }' "$@"
}
