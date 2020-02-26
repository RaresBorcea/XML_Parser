.PHONY: build clean

build: parser

parser: lex.yy.c
	g++ lex.yy.c -o parser

lex.yy.c: parser.l
	lex parser.l

clean:
	rm -rf parser lex.yy.c output.txt
