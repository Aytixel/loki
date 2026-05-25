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

backtrack :: proc {
	backtrack_rune,
	backtrack_runes,
}

backtrack_rune :: proc(reader: io.Reader, ch: rune) -> (err: io.Error) {
	io.seek(reader, cast(i64)-utf8.rune_size(ch), io.Seek_From.Current) or_return
	return
}

backtrack_runes :: proc(reader: io.Reader, runes: []rune) -> (err: io.Error) {
	length := 0

	for ch in runes {
		length += utf8.rune_size(ch)
	}

	io.seek(reader, cast(i64)-length, io.Seek_From.Current) or_return
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
