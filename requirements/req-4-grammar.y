/*
 * A Bison grammar for Phase 4 of the Fortran preprocessor.
 *
 * This grammar assumes the tokenization of the input stream
 * performed in Phase 3. As such, we don't see whitespace
 * or comments. We do see identifiers, whole and real numbers,
 * and tokens that carry additional information.
 *
 * In general, the grammar rules follow Clause 6.10 of
 * the C programming language standard (ISO/IEC 9899:2018, IDT).
 *
 * The grammar rules for expressions represent the Fortran
 * standard's expression rules in clause 10.1.2.
 */

%token                  HASH_DEFINE "#define"
%token                  HASH_ELIF "#elif"
%token                  HASH_ELSE "#else"
%token                  HASH_ENDIF "#endif"
%token                  HASH_ERROR "#error"
%token                  HASH_IF "#if"
%token                  HASH_IFDEF "#ifdef"
%token                  HASH_IFNDEF "#ifndef"
%token                  HASH_INCLUDE "#include"
%token                  HASH_LINE "#line"
%token                  HASH_PRAGMA "#pragma"
%token                  HASH_UNDEF "#undef"
%token                  HASH_WARNING "#warning"

%token                  AMPERSAND "&"
%token                  AMPERSAND_AMPERSAND "&&"
%token                  AT "@"
%token                  BANG "!"
%token                  BANG_EQ "!="
%token                  BAR "|"
%token                  BAR_BAR "||"
%token                  CARET "^"
%token                  COLON ":"
%token                  COLON_COLON "::"
%token                  COMMA ","
%token                  DOLLAR "$"
%token                  ELLIPSES "..."
%token                  EO_ARGS
%token                  EOL
%token                  EQ "="
%token                  EQ_EQ "=="
%token                  FORMAT "format"
%token                  GT ">"
%token                  GT_EQ ">="
%token                  GT_GT ">>"
%token                  HASH "#"
%token                  HASH_HASH "##"
%token                  ID
%token                  ID_LPAREN                       /* only on #define */
%token                  IMPLICIT "implicit"
%token                  LBRACKET "["
%token                  LPAREN "("
%token                  LPAREN_SLASH "(/"
%token                  LT "<"
%token                  LT_EQ "<="
%token                  LT_LT "<<"
%token                  MINUS "-"
%token                  PERCENT "%"
%token                  PERIOD "."
%token                  PERIOD_AND_PERIOD ".and."
%token                  PERIOD_EQ_PERIOD ".eq."
%token                  PERIOD_EQV_PERIOD ".eqv."
%token                  PERIOD_FALSE_PERIOD ".false."
%token                  PERIOD_GE_PERIOD ".ge."
%token                  PERIOD_GT_PERIOD ".gt."
%token                  PERIOD_ID_PERIOD                /* user-defined operator */
%token                  PERIOD_LE_PERIOD ".le."
%token                  PERIOD_LT_PERIOD ".lt."
%token                  PERIOD_NE_PERIOD ".ne."
%token                  PERIOD_NEQV_PERIOD ".neqv."
%token                  PERIOD_NIL_PERIOD "nil."
%token                  PERIOD_NOT_PERIOD ".not."
%token                  PERIOD_OR_PERIOD ".or."
%token                  PERIOD_TRUE_PERIOD ".true."
%token                  PLUS "+"
%token                  POINTS "=>"
%token                  QUESTION "?"
%token                  RBRACKET "]"
%token                  REAL_NUMBER
%token                  RPAREN ")"
%token                  SEMICOLON ";"
%token                  SLASH "/"
%token                  SLASH_EQ "/="
%token                  SLASH_RPAREN "/)"
%token                  SLASH_SLASH "//"
%token                  STRING
%token                  TILDE "~"
%token                  TIMES "*"
%token                  TIMES_TIMES "**"
%token                  UNDERSCORE  "_"                 /* for _KIND, not ID */
%token                  WHOLE_NUMBER

%token                  UND_UND_FILE "__FILE__"
%token                  UND_UND_LINE "__LINE__"
%token                  UND_UND_DATE "__DATE__"
%token                  UND_UND_TIME "__TIME__"
%token                  UND_UND_STDFORTRAN "__STDFORTRAN__"
%token                  UND_UND_STDFORTRAN_VERSION "__STDFORTRAN_VERSION__"
%token                  UND_UND_VA_ARGS "VA_ARGS"
%token                  UND_UND_VA_OPT "VA_OPT"


%%


ExecutableProgram: CommandLineDefinitionList EO_ARGS PreprocessingFile;

CommandLineDefinitionList: %empty;
CommandLineDefinitionList: CommandLineDefinitionList CommandLineDefinition;

CommandLineDefinition: IncludePath EOL;
CommandLineDefinition: DefineArgument EOL;
CommandLineDefinition: UndefineArgument EOL;

IncludePath: HASH_INCLUDE STRING;

DefineArgument: HASH_DEFINE ID ReplacementText;
DefineArgument: HASH_DEFINE ID_LPAREN LambdaList RPAREN ReplacementText;

UndefineArgument: HASH_UNDEF ID;

PreprocessingFile: %empty;
PreprocessingFile: GroupPartList;

/* A GroupPart is some directive, or some Fortran text. */
GroupPartList: GroupPart;
GroupPartList: GroupPartList GroupPart;

GroupPart: IfSection;
GroupPart: ControlLine;
GroupPart: NonDirective;
GroupPart: FortranSourceLine;

IfSection: HASH_IF Expression EOL HASH_ENDIF EOL;
IfSection: HASH_IF Expression EOL ElseGroup HASH_ENDIF EOL;
IfSection: HASH_IF Expression EOL ElifGroupList HASH_ENDIF EOL;
IfSection: HASH_IF Expression EOL ElifGroupList ElseGroup HASH_ENDIF EOL;
IfSection: HASH_IFDEF ID EOL GroupPartList HASH_ENDIF EOL;
IfSection: HASH_IFNDEF ID EOL GroupPartList HASH_ENDIF EOL;

ElifGroupList: HASH_ELIF ID EOL GroupPartList;
ElifGroupList: ElifGroupList HASH_ELIF ID EOL GroupPartList;

ElseGroup: HASH_ELSE EOL GroupPartList;

ControlLine: IncludeControlLine;
ControlLine: DefineIdControlLine;
ControlLine: DefineFunctionControlLine;
ControlLine: LineControlLine;
ControlLine: ErrorControlLine;
ControlLine: WarningControlLine;
ControlLine: PragmaControlLine;

/* TODO Add PPTokens as alternative. */
IncludeControlLine: HASH_INCLUDE STRING EOL;

DefineIdControlLine: HASH_DEFINE ID EOL;
DefineIdControlLine: HASH_DEFINE ID PPTokenList EOL;

/*
 * Parameter lists on macro functions are comma-separated
 * identifiers.
 */
DefineFunctionControlLine: HASH_DEFINE ID_LPAREN LambdaList RPAREN EOL;
DefineFunctionControlLine: HASH_DEFINE ID_LPAREN LambdaList RPAREN ReplacementText EOL;

LambdaList: %empty;
LambdaList: ELLIPSES;
LambdaList: IDList;
LambdaList: IDList COMMA ELLIPSES;

IDList: ID;
IDList: IDList COMMA ID;

LineControlLine: HASH_LINE STRING WHOLE_NUMBER EOL;
LineControlLine: HASH_LINE WHOLE_NUMBER EOL;

ErrorControlLine: HASH_ERROR STRING EOL;

WarningControlLine: HASH_WARNING STRING EOL;

PragmaControlLine: HASH_PRAGMA PPTokenList EOL;

NonDirective: HASH PPTokenList EOL;

ReplacementText: ReplacementToken;
ReplacementText: ReplacementText ReplacementToken;

/*
 * '#' and '##' operators can only appear in the replacement
 * text in #define directives.
 */
ReplacementToken: PPToken;
ReplacementToken: HASH;
ReplacementToken: HASH_HASH;

PPTokenList: PPToken;
PPTokenList: PPTokenList PPToken;

PPToken: FortranToken;
PPToken: CPPToken;

PPTokenListExceptCommaRParen: PPTokenExceptCommaRParen;
PPTokenListExceptCommaRParen: PPTokenListExceptCommaRParen PPTokenExceptCommaRParen;

PPTokenExceptCommaRParen: FortranTokenExceptCommaRParen;
PPTokenExceptCommaRParen: CPPToken;

/*
 * This should include every token that the tokenizer
 * could recognize. The tokenizer has to do some recognition
 * of Fortran operators (such as .AND.) and places where
 * preprocessing expansion should not * occur (such as FORMAT
 * and IMPLICIT).
 */

FortranTokenList: FortranToken;
FortranTokenList: FortranTokenList FortranToken;

FortranToken: FortranTokenAnywhere;
FortranToken: COMMA;
FortranToken: RPAREN;
FortranToken: FORMAT;
FortranToken: IMPLICIT;

FortranTokenExceptCommaRParen: FortranTokenAnywhere;
FortranTokenExceptCommaRParen: FORMAT;
FortranTokenExceptCommaRParen: IMPLICIT;

FortranTokenExceptFormatExplicit: FortranTokenAnywhere;
FortranTokenExceptFormatExplicit: COMMA;
FortranTokenExceptFormatExplicit: RPAREN;

FortranTokenAnywhere: AT;
FortranTokenAnywhere: COLON;
FortranTokenAnywhere: COLON_COLON;
FortranTokenAnywhere: DOLLAR;
FortranTokenAnywhere: EQ;
FortranTokenAnywhere: EQ_EQ;
FortranTokenAnywhere: GT;
FortranTokenAnywhere: GT_EQ;
FortranTokenAnywhere: ID;
FortranTokenAnywhere: LBRACKET;
FortranTokenAnywhere: LPAREN;
FortranTokenAnywhere: LT;
FortranTokenAnywhere: LT_EQ;
FortranTokenAnywhere: MINUS;
FortranTokenAnywhere: PERCENT;
FortranTokenAnywhere: PERIOD;
FortranTokenAnywhere: PERIOD_AND_PERIOD;
FortranTokenAnywhere: PERIOD_EQ_PERIOD;
FortranTokenAnywhere: PERIOD_EQV_PERIOD;
FortranTokenAnywhere: PERIOD_FALSE_PERIOD;
FortranTokenAnywhere: PERIOD_GE_PERIOD;
FortranTokenAnywhere: PERIOD_GT_PERIOD;
FortranTokenAnywhere: PERIOD_ID_PERIOD                /* user-defined operator */;
FortranTokenAnywhere: PERIOD_LE_PERIOD;
FortranTokenAnywhere: PERIOD_LT_PERIOD;
FortranTokenAnywhere: PERIOD_NE_PERIOD;
FortranTokenAnywhere: PERIOD_NEQV_PERIOD;
FortranTokenAnywhere: PERIOD_NIL_PERIOD;
FortranTokenAnywhere: PERIOD_NOT_PERIOD;
FortranTokenAnywhere: PERIOD_OR_PERIOD;
FortranTokenAnywhere: PERIOD_TRUE_PERIOD;
FortranTokenAnywhere: PLUS;
FortranTokenAnywhere: POINTS;
FortranTokenAnywhere: QUESTION;
FortranTokenAnywhere: RBRACKET;
FortranTokenAnywhere: REAL_NUMBER;
FortranTokenAnywhere: SEMICOLON;
FortranTokenAnywhere: SLASH;
FortranTokenAnywhere: SLASH_EQ;
FortranTokenAnywhere: SLASH_SLASH;
FortranTokenAnywhere: STRING;
FortranTokenAnywhere: TIMES;
FortranTokenAnywhere: TIMES_TIMES;
FortranTokenAnywhere: UNDERSCORE                      /* for _KIND, not within ID */;
FortranTokenAnywhere: WHOLE_NUMBER;

FortranTokenListExceptFormatExplicit: FortranTokenExceptFormatExplicit;
FortranTokenListExceptFormatExplicit: FortranTokenListExceptFormatExplicit FortranTokenExceptFormatExplicit;

/*
 * Tokens that can appear in C preprocessor replacement text
 * in addition to the Fortran tokens.
 */
CPPToken: AMPERSAND;
CPPToken: AMPERSAND_AMPERSAND;
CPPToken: BANG;
CPPToken: BANG_EQ;
CPPToken: BAR;
CPPToken: BAR_BAR;
CPPToken: CARET;
CPPToken: GT_GT;
CPPToken: LT_LT;
CPPToken: TILDE;

/* Following Fortran ISO/IEC 1539-1:2023 Clause 10.1.2
 *
 * modified for C-like syntax
 *
 *
 * INCITS and WG5 have agreed (so far) that the preprocessor
 * should conform to a subset of the C preprocessor
 * expression syntax. There has been no consensus
 * to include the standard Fortran operators, but
 * we include them here for completeness. (It is easier
 * to discuss removing them than adding them.)
 *
 * Note that operator precedence differs between C
 * and Fortran. The grammar below attempts to merge
 * these precedence lists, leaning towards C's
 * operator precedence.
 */
Expression: ConditionalExpr;
Expression: Expression EquivOp ConditionalExpr;

EquivOp: PERIOD_EQV_PERIOD;
EquivOp: PERIOD_NEQV_PERIOD;

ConditionalExpr: LogicalOrExpr QUESTION Expression COLON ConditionalExpr;
ConditionalExpr: LogicalOrExpr;

LogicalOrExpr: LogicalAndExpr;
LogicalOrExpr: LogicalOrExpr OrOp LogicalAndExpr;

OrOp: BAR_BAR;
OrOp: PERIOD_OR_PERIOD;

LogicalAndExpr: InclusiveOrExpr;
LogicalAndExpr: LogicalAndExpr AndOp InclusiveOrExpr;

AndOp: AMPERSAND_AMPERSAND;
AndOp: PERIOD_AND_PERIOD;

InclusiveOrExpr: ExclusiveOrExpr;
InclusiveOrExpr: InclusiveOrExpr BAR ExclusiveOrExpr;

ExclusiveOrExpr: AndExpr;
ExclusiveOrExpr: ExclusiveOrExpr CARET AndExpr;

AndExpr: EqualityExpr;
AndExpr: AndExpr AMPERSAND EqualityExpr;

EqualityExpr: RelationalExpr;
EqualityExpr: EqualityExpr EqualityOp RelationalExpr;

EqualityOp: PERIOD_EQ_PERIOD;
EqualityOp: PERIOD_NE_PERIOD;
EqualityOp: EQ_EQ;
EqualityOp: SLASH_EQ;
EqualityOp: BANG_EQ;

RelationalExpr: ShiftExpr;
RelationalExpr: RelationalExpr RelationalOp ShiftExpr;

RelationalOp: PERIOD_LE_PERIOD;
RelationalOp: PERIOD_LT_PERIOD;
RelationalOp: PERIOD_GE_PERIOD;
RelationalOp: PERIOD_GT_PERIOD;
RelationalOp: LT;
RelationalOp: GT;
RelationalOp: LT_EQ;
RelationalOp: GT_EQ;

ShiftExpr: CharacterExpr;
ShiftExpr: ShiftExpr ShiftOp CharacterExpr;

ShiftOp: LT_LT;
ShiftOp: GT_GT;

CharacterExpr: AdditiveExpr;
CharacterExpr: CharacterExpr SLASH_SLASH AdditiveExpr;

AdditiveExpr: MultiplicativeExpr;
AdditiveExpr: AdditiveExpr AddOp MultiplicativeExpr;

AddOp: PLUS;
AddOp: MINUS;

MultiplicativeExpr: PowerExpr;
MultiplicativeExpr: MultiplicativeExpr MultOp PowerExpr;

MultOp: TIMES;
MultOp: SLASH;
MultOp: PERCENT;

PowerExpr: UnaryExpr;
PowerExpr: UnaryExpr TIMES_TIMES PowerExpr;

UnaryExpr: UnaryOp PostfixExpr;
UnaryExpr: PostfixExpr;

UnaryOp: PLUS;
UnaryOp: MINUS;
UnaryOp: PERIOD_NOT_PERIOD;
UnaryOp: BANG;
UnaryOp: TILDE;

PostfixExpr: PrimaryExpr;
PostfixExpr: ID LPAREN RPAREN;
PostfixExpr: ID LPAREN ActualArgumentList RPAREN;

/* TODO: Really this should be properly nested parenthesized lists */
ActualArgumentList: PPTokenListExceptCommaRParen;
ActualArgumentList: ActualArgumentList COMMA PPTokenListExceptCommaRParen;

/* Real numbers aren't allowed in conditional explessions */
PrimaryExpr: WHOLE_NUMBER;
PrimaryExpr: ID;
PrimaryExpr: PERIOD_FALSE_PERIOD;
PrimaryExpr: PERIOD_NIL_PERIOD;
PrimaryExpr: PERIOD_TRUE_PERIOD;
PrimaryExpr: LPAREN Expression RPAREN;
PrimaryExpr: PredefinedIdentifier;

/* Identifiers known to the preprocessor (such as __FILE__) */
PredefinedIdentifier: UND_UND_FILE;
PredefinedIdentifier: UND_UND_LINE;
PredefinedIdentifier: UND_UND_DATE;
PredefinedIdentifier: UND_UND_TIME;
PredefinedIdentifier: UND_UND_STDFORTRAN;
PredefinedIdentifier: UND_UND_STDFORTRAN_VERSION;
PredefinedIdentifier: UND_UND_VA_ARGS;
PredefinedIdentifier: UND_UND_VA_OPT;
    /* | ProcessorDefinedPPIdentifier */

/* /\* Implementation-defined predefined identifiers *\/ */
/* ProcessorDefinedPPIdentifier: */
/*       ; */

FortranSourceLine: EOL;
FortranSourceLine: FORMAT FortranTokenList EOL;
FortranSourceLine: IMPLICIT FortranTokenList EOL;
FortranSourceLine: FortranTokenListExceptFormatExplicit EOL;
