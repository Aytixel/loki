package lexer

import "core:math/big"
import "core:unicode/utf8"

Lexem :: struct {
	atom:       LexemAtom,
	// position
	line:       int,
	start:      int,
	rune_start: int,
	end:        int,
	rune_end:   int,
}

@(private)
lexem_from :: proc {
	lexem_from_rune,
	lexem_from_string,
}

@(private)
lexem_destroy :: proc(lexem: Lexem) {
	switch atom in lexem.atom {
	case WhiteSpace:
	case LineTerminator:
		delete(string(atom))
	case Comments:
		delete(string(atom))
	case HashbangComments:
		delete(string(atom))
	case Identifier:
		delete(string(atom))
	case PrivateIdentifier:
		delete(string(atom))
	case LabelIdentifer:
		delete(string(atom))
	case StringLiteral:
		delete(string(atom))
	case Template:
		delete(string(atom))
	case NumericalLiteral:
		switch &v in atom {
		case f64:
		case big.Int:
			big.destroy(&v)
		}
	case Keyword:
	case Punctuator:
	}
}

@(private)
lexem_from_rune :: proc(lexer: ^Lexer, ch: rune, atom: LexemAtom) -> Lexem {
	return Lexem {
		atom = atom,
		line = lexer.line,
		start = lexer.position,
		rune_start = lexer.rune_position,
		end = lexer.position + utf8.rune_size(ch),
		rune_end = lexer.rune_position + 1,
	}
}

@(private)
lexem_from_string :: proc(lexer: ^Lexer, s: string, atom: LexemAtom) -> Lexem {
	return Lexem {
		atom = atom,
		line = lexer.line,
		start = lexer.position,
		rune_start = lexer.rune_position,
		end = lexer.position + len(s),
		rune_end = lexer.rune_position + utf8.rune_count(s),
	}
}

LexemAtom :: union #no_nil {
	WhiteSpace,
	LineTerminator,
	Comments,
	HashbangComments,
	Keyword,
	Identifier,
	PrivateIdentifier,
	LabelIdentifer,
	NumericalLiteral,
	StringLiteral,
	Punctuator,
	Template,
}

WhiteSpace :: distinct rune
LineTerminator :: distinct string
Comments :: distinct string
HashbangComments :: distinct string
Identifier :: distinct string
PrivateIdentifier :: distinct string
LabelIdentifer :: distinct string

NumericalLiteral :: union #no_nil {
	f64,
	big.Int,
}

StringLiteral :: distinct string
Template :: distinct string
RegularExpressionLiteral :: distinct string

Keyword :: enum {
	Await,
	Break,
	Case,
	Catch,
	Class,
	Const,
	Continue,
	Debugger,
	Default,
	Delete,
	Do,
	Else,
	Enum,
	Export,
	Extends,
	False,
	Finally,
	For,
	Function,
	If,
	Import,
	In,
	Instanceof,
	Let,
	New,
	Null,
	Return,
	Super,
	Switch,
	This,
	Throw,
	True,
	Try,
	Typeof,
	Var,
	Void,
	While,
	With,
	Yield,
}

Punctuator :: enum {
	OptionalChaining,
	LeftBrace,
	RightBrace,
	LeftParenthesis,
	RightParenthesis,
	LeftBracket,
	RightBracket,
	Dot,
	Spread,
	SemiColon,
	Colon,
	Comma,
	QuestionMark,
	Lower,
	Greater,
	LowerOrEqual,
	GreaterOrEqual,
	Equal,
	NotEqual,
	StrictlyEqual,
	StrictlyNotEqual,
	LogicalNot,
	LogicalAnd,
	LogicalOr,
	Increment,
	Decrement,
	Plus,
	Minus,
	Multiply,
	Division,
	Remainder,
	Power,
	LeftShift,
	RightShift,
	UnsignedRightShift,
	BitwiseAnd,
	BitwiseOr,
	BitwiseXor,
	BitwiseNot,
	NullishCoalescing,
	Arrow,
	Assignment,
	PlusAssignment,
	MinusAssignment,
	DivisionAssignment,
	MultiplyAssignment,
	RemainderAssignment,
	PowerAssignment,
	LeftShiftAssignment,
	RightShiftAssignment,
	UnsignedRightShiftAssignment,
	BitwiseAndAssignment,
	BitwiseOrAssignment,
	BitwiseXorAssignment,
	BitwiseNotAssignment,
	LogicalAndAssignment,
	LogicalOrAssignment,
	NullishCoalescingAssignment,
}
