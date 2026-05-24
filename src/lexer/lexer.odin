package lexer

import "core:io"
import "core:slice"
import "core:unicode/utf8"

Lexer :: struct {
	lexems:        [dynamic]Lexem,
	// cursor
	line:          int,
	position:      int,
	rune_position: int,
}

init :: proc(lexer: ^Lexer) {
	lexer.lexems = make([dynamic]Lexem, 0, 1024)
	lexer.line = 0
	lexer.position = 0
	lexer.rune_position = 0
}

destroy :: proc(lexer: ^Lexer) {
	for lexem in lexer.lexems {
		lexem_destroy(lexem)
	}
	delete(lexer.lexems)
}

lex :: proc(lexer: ^Lexer, reader: io.Reader) -> (err: io.Error) {
	for {
		ch := read_rune(reader) or_return
		if ch == 0 {
			return
		}
		defer move_position(lexer, ch)

		for lex_proc in lex_procs {
			if lex_proc(lexer, reader, ch) or_return {
				break
			}
		}
	}

	return
}

lex_procs :: [](proc(lexer: ^Lexer, reader: io.Reader, ch: rune) -> (ok: bool, err: io.Error)) {
	lex_line_terminator,
	lex_white_space,
	lex_hashbang_comments,
	lex_keyword,
	lex_punctuator,
}

line_terminators := []rune{'\n', '\r', '\u2028', '\u2029'}

@(private)
lex_line_terminator :: proc(
	lexer: ^Lexer,
	reader: io.Reader,
	ch: rune,
) -> (
	ok: bool,
	err: io.Error,
) {
	if !slice.contains(line_terminators, ch) {
		return false, io.Error.None
	}

	runes := []rune{ch}

	if ch == '\r' {
		lf_ch := read_rune(reader) or_return

		if lf_ch == '\n' {
			runes = {ch, lf_ch}
		} else {
			backtrack(reader, lf_ch) or_return
		}
	}

	s := utf8.runes_to_string(runes)

	non_zero_append(&lexer.lexems, lexem_from(lexer, s, LineTerminator(s)))

	if len(runes) == 2 {
		move_position(lexer, runes[1])
	}

	return true, io.Error.None
}

white_spaces := []rune {
	'\t',
	'\v',
	'\f',
	'\uEFFF',
	'\u0020',
	'\u00A0',
	'\u1680',
	'\u2000',
	'\u2002',
	'\u2003',
	'\u2004',
	'\u2005',
	'\u2006',
	'\u2007',
	'\u2008',
	'\u2009',
	'\u200A',
	'\u202F',
	'\u205F',
	'\u3000',
}

@(private)
lex_white_space :: proc(lexer: ^Lexer, reader: io.Reader, ch: rune) -> (ok: bool, err: io.Error) {
	if slice.contains(white_spaces, ch) {
		non_zero_append(&lexer.lexems, lexem_from(lexer, ch, WhiteSpace(ch)))
		return true, io.Error.None
	}

	return false, io.Error.None
}

@(private)
lex_hashbang_comments :: proc(
	lexer: ^Lexer,
	reader: io.Reader,
	ch: rune,
) -> (
	ok: bool,
	err: io.Error,
) {
	if ch != '#' {
		return false, io.Error.None
	}

	mark_ch := read_rune(reader) or_return
	if mark_ch != '!' {
		backtrack(reader, mark_ch) or_return
		return false, io.Error.None
	}

	runes: [dynamic]rune
	defer delete(runes)

	for {
		ch := read_rune(reader) or_return

		if ch == 0 || slice.contains(line_terminators, ch) {
			backtrack(reader, ch) or_return
			break
		}

		non_zero_append(&runes, ch)
	}

	s := utf8.runes_to_string(runes[:])

	lexem := lexem_from(lexer, s, HashbangComments(s))
	lexem.end += 2
	lexem.rune_end += 2
	non_zero_append(&lexer.lexems, lexem)

	move_position(lexer, s)
	move_position(lexer, mark_ch)

	return true, io.Error.None
}

@(private)
lex_keyword :: proc(lexer: ^Lexer, reader: io.Reader, ch: rune) -> (ok: bool, err: io.Error) {
	return false, io.Error.None
}

@(private)
lex_punctuator :: proc(lexer: ^Lexer, reader: io.Reader, ch: rune) -> (ok: bool, err: io.Error) {
	lexem: Lexem
	runes: [dynamic; 4]rune = {ch}

	switch (ch) {
	case '(':
		lexem = lexem_from(lexer, ch, Punctuator.LeftParenthesis)
	case ')':
		lexem = lexem_from(lexer, ch, Punctuator.RightParenthesis)
	case '[':
		lexem = lexem_from(lexer, ch, Punctuator.LeftBracket)
	case ']':
		lexem = lexem_from(lexer, ch, Punctuator.RightBracket)
	case '{':
		lexem = lexem_from(lexer, ch, Punctuator.LeftBrace)
	case '}':
		lexem = lexem_from(lexer, ch, Punctuator.RightBrace)
	case ';':
		lexem = lexem_from(lexer, ch, Punctuator.SemiColon)
	case ':':
		lexem = lexem_from(lexer, ch, Punctuator.Colon)
	case ',':
		lexem = lexem_from(lexer, ch, Punctuator.Comma)
	case '.':
		lexem = lexem_from(lexer, ch, Punctuator.Dot)
	case '+':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.PlusAssignment,
			Punctuator.Plus,
		) or_return
	case '-':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.MinusAssignment,
			Punctuator.Minus,
		) or_return
	case '*':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.MultiplyAssignment,
			Punctuator.Multiply,
		) or_return
	case '/':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.DivisionAssignment,
			Punctuator.Division,
		) or_return
	case '%':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.RemainderAssignment,
			Punctuator.Remainder,
		) or_return
	case '?':
		append_read_rune(&runes, reader) or_return

		if runes[1] == '?' {
			append_read_rune(&runes, reader) or_return
			lexem = choose_punctuator(
				lexer,
				reader,
				&runes,
				2,
				'=',
				Punctuator.NullishCoalescingAssignment,
				Punctuator.NullishCoalescing,
			) or_return
			break
		}

		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'.',
			Punctuator.OptionalChaining,
			Punctuator.QuestionMark,
		) or_return
	case '=':
		append_read_rune(&runes, reader) or_return

		if runes[1] == '=' {
			append_read_rune(&runes, reader) or_return
			lexem = choose_punctuator(
				lexer,
				reader,
				&runes,
				2,
				'=',
				Punctuator.StrictlyEqual,
				Punctuator.Equal,
			) or_return
			break
		}

		lexem = lexem_from(lexer, runes[:], Punctuator.Assignment)
		backtrack(reader, pop(&runes))
	case '!':
		append_read_rune(&runes, reader) or_return

		if runes[1] == '=' {
			append_read_rune(&runes, reader) or_return
			lexem = choose_punctuator(
				lexer,
				reader,
				&runes,
				2,
				'=',
				Punctuator.StrictlyNotEqual,
				Punctuator.NotEqual,
			) or_return
			break
		}

		lexem = lexem_from(lexer, ch, Punctuator.LogicalNot)
		backtrack(reader, pop(&runes))
	case '<':
		append_read_rune(&runes, reader) or_return

		if runes[1] == '<' {
			append_read_rune(&runes, reader) or_return
			lexem = choose_punctuator(
				lexer,
				reader,
				&runes,
				2,
				'=',
				Punctuator.LeftShiftAssignment,
				Punctuator.LeftShift,
			) or_return
			break
		}

		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.LowerOrEqual,
			Punctuator.Lower,
		) or_return
	case '>':
		append_read_rune(&runes, reader) or_return

		if runes[1] == '>' {
			append_read_rune(&runes, reader) or_return

			if runes[2] == '>' {
				append_read_rune(&runes, reader) or_return
				lexem = choose_punctuator(
					lexer,
					reader,
					&runes,
					3,
					'=',
					Punctuator.UnsignedRightShiftAssignment,
					Punctuator.UnsignedRightShift,
				) or_return
				break
			}

			lexem = choose_punctuator(
				lexer,
				reader,
				&runes,
				2,
				'=',
				Punctuator.RightShiftAssignment,
				Punctuator.RightShift,
			) or_return
			break
		}

		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.GreaterOrEqual,
			Punctuator.Greater,
		) or_return
	case '^':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.BitwiseXorAssignment,
			Punctuator.BitwiseXor,
		) or_return
	case '|':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.BitwiseOrAssignment,
			Punctuator.BitwiseOr,
		) or_return
	case '&':
		append_read_rune(&runes, reader) or_return
		lexem = choose_punctuator(
			lexer,
			reader,
			&runes,
			1,
			'=',
			Punctuator.BitwiseAndAssignment,
			Punctuator.BitwiseAnd,
		) or_return
	case '~':
		lexem = lexem_from(lexer, ch, Punctuator.BitwiseNot)
	case:
		return false, io.Error.None
	}

	non_zero_append(&lexer.lexems, lexem)
	move_position(lexer, runes[1:])

	return true, io.Error.None
}

@(private)
choose_punctuator :: proc(
	lexer: ^Lexer,
	reader: io.Reader,
	runes: ^[dynamic; $N]rune,
	check_index: u8,
	check_ch: rune,
	choosed_punctuator: Punctuator,
	other_punctuator: Punctuator,
) -> (
	lexem: Lexem,
	err: io.Error,
) {
	if runes[check_index] == check_ch {
		lexem = lexem_from(lexer, runes[:], choosed_punctuator)
	} else {
		backtrack(reader, pop(runes)) or_return
		lexem = lexem_from(lexer, runes[:], other_punctuator)
	}
	return
}

@(private)
append_read_rune :: proc(runes: ^[dynamic; $N]rune, reader: io.Reader) -> (err: io.Error) {
	ch := read_rune(reader) or_return
	append(runes, ch)
	return
}
