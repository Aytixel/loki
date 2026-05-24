#+private
package lexer

import "core:io"
import "core:strings"
import "core:unicode/utf8"

Move :: enum {
	Forward,
	Backward,
}

move_position :: proc {
	move_position_rune,
	move_position_runes,
	move_position_string,
}

move_position_rune :: proc(lexer: ^Lexer, ch: rune, move: Move = Move.Forward) {
	sign := move == Move.Forward ? 1 : -1

	if ch == '\n' {
		lexer.line += sign
	}

	lexer.position += utf8.rune_size(ch) * sign
	lexer.rune_position += sign
}

move_position_runes :: proc(lexer: ^Lexer, runes: []rune, move: Move = Move.Forward) {
	for ch in runes {
		move_position_rune(lexer, ch, move)
	}
}

move_position_string :: proc(lexer: ^Lexer, s: string, move: Move = Move.Forward) {
	for ch in s {
		move_position_rune(lexer, ch, move)
	}
}

backtrack :: proc {
	backtrack_rune,
	backtrack_string,
}

backtrack_rune :: proc(reader: io.Reader, ch: rune) -> (err: io.Error) {
	io.seek(reader, cast(i64)-utf8.rune_size(ch), io.Seek_From.Current) or_return
	return
}

backtrack_string :: proc(reader: io.Reader, s: string) -> (err: io.Error) {
	io.seek(reader, cast(i64)-len(s), io.Seek_From.Current) or_return
	return
}

read_rune :: proc(reader: io.Reader) -> (ch: rune, err: io.Error) {
	size: int
	ch, size, err = io.read_rune(reader)
	if err == io.Error.EOF {
		ch = 0
		err = io.Error.None
	}
	return
}

read_string :: proc(reader: io.Reader, n: int) -> (s: string, err: io.Error) {
	runes: [dynamic]rune
	defer delete(runes)

	for _ in 0 ..< n {
		ch := read_rune(reader) or_return
		append(&runes, ch)
	}

	s = utf8.runes_to_string(runes[:])
	return
}

peek_rune :: proc(reader: io.Reader) -> (ch: rune, err: io.Error) {
	ch = read_rune(reader) or_return
	backtrack(reader, ch) or_return
	return
}

peek_string :: proc(reader: io.Reader, n: int) -> (s: string, err: io.Error) {
	defer if err != nil {
		delete(s)
	}

	s = read_string(reader, n) or_return
	backtrack(reader, s) or_return
	return
}

advance :: proc(reader: io.Reader) -> (err: io.Error) {
	read_rune(reader) or_return
	return
}

advance_n :: proc(reader: io.Reader, n: int) -> (err: io.Error) {
	for _ in 0 ..< n {
		read_rune(reader) or_return
	}

	return
}
