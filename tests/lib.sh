# tiny test helpers; T = dir holding the tools (default: ../bin of the kit, override with TOOLS=)
P=0; F=0
ok(){ if eval "$2" >/dev/null 2>&1; then echo "PASS: $1"; P=$((P+1)); else echo "FAIL: $1"; F=$((F+1)); fi; }
done_(){ echo "$P/$((P+F)) passed"; [ $F -eq 0 ]; }
