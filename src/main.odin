package main

import "core:fmt"
import "core:io"
import "core:os"

import "lexer"

main :: proc() {
	if len(os.args) <= 1 {
		return
	}

	filepath := os.args[1]

	f, err := os.open(filepath)
	if err != io.Error.None {
		fmt.println(os.error_string(err), filepath, sep = ": ")
		return
	}
	defer os.close(f)

	r := os.to_reader(f)

	l: lexer.Lexer
	lexer.init(&l)
	defer lexer.destroy(&l)

	err = lexer.lex(&l, r)
	if err != io.Error.None {
		fmt.println(os.error_string(err), filepath, sep = ": ")
		return
	}

	for lexem in l.lexems {
		fmt.printfln("%w", lexem)
	}
}
