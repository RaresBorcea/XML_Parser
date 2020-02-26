# Borcea Rares Ioan Grupa 334CC

.PHONY: build clean

build: tema

tema: lex.yy.c
	g++ lex.yy.c -o tema

lex.yy.c: tema.l
	lex tema.l

clean:
	rm -rf tema lex.yy.c output.txt