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


ExecutableProgram:
      CommandLineDefinitionList EO_ARGS PreprocessingFile
      ;

CommandLineDefinitionList:
      %empty
    | CommandLineDefinitionList CommandLineDefinition
      ;

CommandLineDefinition:
      IncludePath EOL
    | DefineArgument EOL
    | UndefineArgument EOL
      ;

IncludePath:
      HASH_INCLUDE STRING
      ;

DefineArgument:
      HASH_DEFINE ID ReplacementText
    | HASH_DEFINE ID_LPAREN LambdaList RPAREN ReplacementText
      ;

UndefineArgument:
      HASH_UNDEF ID
      ;

PreprocessingFile:
      %empty
    | GroupPartList
      ;

/* A GroupPart is some directive, or some Fortran text. */
GroupPartList:
      GroupPart
    | GroupPartList GroupPart
      ;

GroupPart:
      IfSection
    | ControlLine
    | NonDirective
    | FortranSourceLine
      ;

IfSection:
      HASH_IF Expression EOL HASH_ENDIF EOL
    | HASH_IF Expression EOL ElseGroup HASH_ENDIF EOL
    | HASH_IF Expression EOL ElifGroupList HASH_ENDIF EOL
    | HASH_IF Expression EOL ElifGroupList ElseGroup HASH_ENDIF EOL
    | HASH_IFDEF ID EOL GroupPartList HASH_ENDIF EOL
    | HASH_IFNDEF ID EOL GroupPartList HASH_ENDIF EOL
      ;

ElifGroupList:
      HASH_ELIF ID EOL GroupPartList
    | ElifGroupList HASH_ELIF ID EOL GroupPartList
      ;

ElseGroup:
      HASH_ELSE EOL GroupPartList
      ;

ControlLine:
      IncludeControlLine
    | DefineIdControlLine
    | DefineFunctionControlLine
    | LineControlLine
    | ErrorControlLine
    | WarningControlLine
    | PragmaControlLine
      ;

/* TODO Add PPTokens as alternative. */
IncludeControlLine:
      HASH_INCLUDE STRING EOL
      ;

DefineIdControlLine:
      HASH_DEFINE ID EOL
    | HASH_DEFINE ID PPTokenList EOL
      ;

/*
 * Parameter lists on macro functions are comma-separated
 * identifiers.
 */
DefineFunctionControlLine:
      HASH_DEFINE ID_LPAREN LambdaList RPAREN EOL
    | HASH_DEFINE ID_LPAREN LambdaList RPAREN ReplacementText EOL
      ;

LambdaList:
      %empty
    | ELLIPSES
    | IDList
    | IDList COMMA ELLIPSES
      ;

IDList:
      ID
    | IDList COMMA ID
      ;

LineControlLine:
      HASH_LINE STRING WHOLE_NUMBER EOL
    | HASH_LINE WHOLE_NUMBER EOL
      ;

ErrorControlLine:
      HASH_ERROR STRING EOL
      ;

WarningControlLine:
      HASH_WARNING STRING EOL
      ;

PragmaControlLine:
      HASH_PRAGMA PPTokenList EOL
      ;

NonDirective:
      HASH PPTokenList EOL
      ;

ReplacementText:
      ReplacementToken
    | ReplacementText ReplacementToken
      ;

/*
 * '#' and '##' operators can only appear in the replacement
 * text in #define directives.
 */
ReplacementToken:
      PPToken
    | HASH
    | HASH_HASH
      ;

PPTokenList:
      PPToken
    | PPTokenList PPToken
      ;

PPToken:
      FortranToken
    | CPPToken
      ;

PPTokenListExceptCommaRParen:
      PPTokenExceptCommaRParen
    | PPTokenListExceptCommaRParen PPTokenExceptCommaRParen
    ;

PPTokenExceptCommaRParen:
      FortranTokenExceptCommaRParen
    | CPPToken
      ;

/*
 * This should include every token that the tokenizer
 * could recognize. The tokenizer has to do some recognition
 * of Fortran operators (such as .AND.) and places where
 * preprocessing expansion should not * occur (such as FORMAT
 * and IMPLICIT).
 */

FortranTokenList:
      FortranToken
    | FortranTokenList FortranToken
    ;

FortranToken:
      FortranTokenAnywhere
    | COMMA
    | RPAREN
    | FORMAT
    | IMPLICIT
    ;

FortranTokenExceptCommaRParen:
      FortranTokenAnywhere
    | FORMAT
    | IMPLICIT
    ;

FortranTokenExceptFormatExplicit:
      FortranTokenAnywhere
    | COMMA
    | RPAREN
    ;

FortranTokenAnywhere:
      AT
    | COLON
    | COLON_COLON
    | DOLLAR
    | EQ
    | EQ_EQ
    | GT
    | GT_EQ
    | ID
    | LBRACKET
    | LPAREN
    | LT
    | LT_EQ
    | MINUS
    | PERCENT
    | PERIOD
    | PERIOD_AND_PERIOD
    | PERIOD_EQ_PERIOD
    | PERIOD_EQV_PERIOD
    | PERIOD_FALSE_PERIOD
    | PERIOD_GE_PERIOD
    | PERIOD_GT_PERIOD
    | PERIOD_ID_PERIOD                /* user-defined operator */
    | PERIOD_LE_PERIOD
    | PERIOD_LT_PERIOD
    | PERIOD_NE_PERIOD
    | PERIOD_NEQV_PERIOD
    | PERIOD_NIL_PERIOD
    | PERIOD_NOT_PERIOD
    | PERIOD_OR_PERIOD
    | PERIOD_TRUE_PERIOD
    | PLUS
    | POINTS
    | QUESTION
    | RBRACKET
    | REAL_NUMBER
    | SEMICOLON
    | SLASH
    | SLASH_EQ
    | SLASH_SLASH
    | STRING
    | TIMES
    | TIMES_TIMES
    | UNDERSCORE                      /* for _KIND, not within ID */
    | WHOLE_NUMBER
      ;

FortranTokenListExceptFormatExplicit:
      FortranTokenExceptFormatExplicit
    | FortranTokenListExceptFormatExplicit FortranTokenExceptFormatExplicit
      ;

/*
 * Tokens that can appear in C preprocessor replacement text
 * in addition to the Fortran tokens.
 */
CPPToken:
      AMPERSAND
    | AMPERSAND_AMPERSAND
    | BANG
    | BANG_EQ
    | BAR
    | BAR_BAR
    | CARET
    | GT_GT
    | LT_LT
    | TILDE
      ;

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
Expression:
      ConditionalExpr
    | Expression EquivOp ConditionalExpr
      ;

EquivOp:
      PERIOD_EQV_PERIOD
    | PERIOD_NEQV_PERIOD
      ;

ConditionalExpr:
      LogicalOrExpr QUESTION Expression COLON ConditionalExpr
    | LogicalOrExpr
      ;

LogicalOrExpr:
      LogicalAndExpr
    | LogicalOrExpr OrOp LogicalAndExpr
      ;

OrOp:
      BAR_BAR
    | PERIOD_OR_PERIOD
      ;

LogicalAndExpr:
      InclusiveOrExpr
    | LogicalAndExpr AndOp InclusiveOrExpr
      ;

AndOp:
      AMPERSAND_AMPERSAND
    | PERIOD_AND_PERIOD
      ;

InclusiveOrExpr:
      ExclusiveOrExpr
    | InclusiveOrExpr BAR ExclusiveOrExpr
      ;

ExclusiveOrExpr:
      AndExpr
    | ExclusiveOrExpr CARET AndExpr
      ;

AndExpr:
      EqualityExpr
    | AndExpr AMPERSAND EqualityExpr
      ;

EqualityExpr:
      RelationalExpr
    | EqualityExpr EqualityOp RelationalExpr
      ;

EqualityOp:
      PERIOD_EQ_PERIOD
    | PERIOD_NE_PERIOD
    | EQ_EQ
    | SLASH_EQ
    | BANG_EQ
      ;

RelationalExpr:
      ShiftExpr
    | RelationalExpr RelationalOp ShiftExpr
      ;

RelationalOp:
      PERIOD_LE_PERIOD
    | PERIOD_LT_PERIOD
    | PERIOD_GE_PERIOD
    | PERIOD_GT_PERIOD
    | LT
    | GT
    | LT_EQ
    | GT_EQ
      ;

ShiftExpr:
      CharacterExpr
    | ShiftExpr ShiftOp CharacterExpr
      ;

ShiftOp:
      LT_LT
    | GT_GT
      ;

CharacterExpr:
      AdditiveExpr
    | CharacterExpr SLASH_SLASH AdditiveExpr
      ;

AdditiveExpr:
      MultiplicativeExpr
    | AdditiveExpr AddOp MultiplicativeExpr
      ;

AddOp:
      PLUS
    | MINUS
      ;

MultiplicativeExpr:
      PowerExpr
    | MultiplicativeExpr MultOp PowerExpr
      ;

MultOp:
      TIMES
    | SLASH
    | PERCENT
      ;

PowerExpr:
      UnaryExpr
    | UnaryExpr TIMES_TIMES PowerExpr
      ;

UnaryExpr:
      UnaryOp PostfixExpr
    | PostfixExpr
      ;

UnaryOp:
      PLUS
    | MINUS
    | PERIOD_NOT_PERIOD
    | BANG
    | TILDE
      ;

PostfixExpr:
      PrimaryExpr
    | ID LPAREN RPAREN
    | ID LPAREN ActualArgumentList RPAREN
      ;

/* TODO: Really this should be properly nested parenthesized lists */
ActualArgumentList:
      PPTokenListExceptCommaRParen
    | ActualArgumentList COMMA PPTokenListExceptCommaRParen
      ;

/* Real numbers aren't allowed in conditional explessions */
PrimaryExpr:
      WHOLE_NUMBER
    | ID
    | PERIOD_FALSE_PERIOD
    | PERIOD_NIL_PERIOD
    | PERIOD_TRUE_PERIOD
    | LPAREN Expression RPAREN
    | PredefinedIdentifier
      ;

/* Identifiers known to the preprocessor (such as __FILE__) */
PredefinedIdentifier:
      UND_UND_FILE
    | UND_UND_LINE
    | UND_UND_DATE
    | UND_UND_TIME
    | UND_UND_STDFORTRAN
    | UND_UND_STDFORTRAN_VERSION
    | UND_UND_VA_ARGS
    | UND_UND_VA_OPT
    /* | ProcessorDefinedPPIdentifier */
      ;

/* /\* Implementation-defined predefined identifiers *\/ */
/* ProcessorDefinedPPIdentifier: */
/*       ; */

FortranSourceLine:
      EOL
    | FORMAT FortranTokenList EOL
    | IMPLICIT FortranTokenList EOL
    | FortranTokenListExceptFormatExplicit EOL
      ;
