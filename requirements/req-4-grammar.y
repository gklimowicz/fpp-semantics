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

%code top {
    #define _GNU_SOURCE
    #include <stdio.h>

    int yylex (void);
    void yyerror (char const *);
}

%code requires {
    #define YYLTYPE YYLTYPE
    /* Location type, for source code origin of tokens */
    typedef struct YYLTYPE
    {
        int first_line;
        int first_column;
        int last_line;
        int last_column;
        char *filename;
    } YYLTYPE;

}

%code {
    /* Parse stack values:
     * - nothing of interest
     * - an integer
     * - a string
     * - a token list
     * - an environment: scope + current ast
     */
    typedef union YYSTYPE {
        int               y_noval;
        yytoken_kind_t    y_token;
        int               y_ival;
        char              *y_sval;
        struct token_list *y_tokens;
        struct ast        *y_ast;
        struct scope      *y_scope;
        struct env        *y_env;
        struct def        *y_def;
        struct path_list  *y_paths;
        YYLTYPE           y_loc;
    } YYSTYPE;

    /* Tokens have a type, a location, and possibly
                        an additional value. */
    typedef struct token {
        yytoken_kind_t  t_token;
        YYLTYPE         t_loc;
        YYSTYPE         t_val;
    } token_t;

    /* Macro definitions are made up of lists of tokens
     * (to expand later).
     * Represented as a queue.
     */
    typedef struct token_list {
        struct token_elt    *t_first;
        struct token_elt    *t_last;
    } token_list_t;

    typedef struct token_elt {
        YYSTYPE             *t_token;
        struct token_elt    *t_next;
    } token_elt_t;

    token_list_t *new_token_list();
    token_list_t *append_token(token_list_t *token_list, token_t token);
    token_list_t *append_token_list(token_list_t *head,
                        token_list_t *new_tail);
    token_list_t *cons_token(token_t token, token_list_t *token_list);

    /* Path lists as defined by preprocessor and command arguments.
     * Represented as a queue.
     */
    typedef struct path_list {
        struct path_elt    *t_first;
        struct path_elt    *t_last;
    } path_list_t;

    typedef struct path_elt {
        char                *t_path;
        struct path_elt     *t_next;
    } path_elt_t;

    path_list_t *append_path(char *path, path_list_t *path_list);

    /* Abstract syntax tree: an op, a location, and a set of operands. */
    typedef struct ast {
        int         a_op;
        YYLTYPE     a_loc;
        YYSTYPE     a_v1, a_v2, a_v3;
    } ast_t;

    ast_t *new_ast(token_t op, YYLTYPE loc;
                        YYSTYPE *v1, YYSTYPE *v2, YYSTYPE *v3);

    /* Macro definition: an id, a list of arguments,
     * and a token-list definition.
     */
    typedef struct def {
        char         *d_id;
        int          d_nargs;   /* -1 if no arg list, even empty */
        token_list_t *d_args;
        token_list_t *d_defn;
    } def_t;

    /* List of macro definitions within a scope. */
    typedef struct defs_list {
        def_t        *d_def;
        struct defs_list *d_next;
    } def_list_t;

    /* Scope stack, separating definitions in each scope.
     * Represented as a stack.
     * I think there are only two:
     * - From the command line
     * - From within the file (and all its included files)
     */
    typedef struct scope {
        struct scope     *s_outer;
        struct path_list *s_paths;
        def_list_t       *s_defs;
    } scope_t;

    scope_t *create_empty_scope();
    scope_t *add_path(scope_t *cur, char *path);
    scope_t *add_defn(scope_t *cur, char *id, token_list_t *text);
    scope_t *add_defn_fin(scope_t *cur, char *id,
                        token_list_t *args, token_list_t *text);
    scope_t *rm_defn(scope_t *cur, char *id);

    /* The environment, passed from production to production. */
    typedef struct env {
        struct scope      *e_scope;
        struct ast        *e_ast;
        struct token_list *e_tokens;
    } env_t;

    env_t *new_env(scope_t *scope);
    env_t *update_env(scope_t *scope, ast_t *ast);
    env_t *eval(ast_t *ast, env_t env);
    token_list_t *expand_tokens(env_t *env, token_list_t *tokens);

}

%define api.value.type {union YYSTYPE}

%token  <y_noval>       HASH_DEFINE "#define"
%token  <y_noval>       HASH_ELIF "#elif"
%token  <y_noval>       HASH_ELSE "#else"
%token  <y_noval>       HASH_ENDIF "#endif"
%token  <y_noval>       HASH_ERROR "#error"
%token  <y_noval>       HASH_IF "#if"
%token  <y_noval>       HASH_IFDEF "#ifdef"
%token  <y_noval>       HASH_IFNDEF "#ifndef"
%token  <y_noval>       HASH_INCLUDE "#include"
%token  <y_noval>       HASH_LINE "#line"
%token  <y_noval>       HASH_PRAGMA "#pragma"
%token  <y_noval>       HASH_UNDEF "#undef"
%token  <y_noval>       HASH_WARNING "#warning"

%token  <y_noval>       AMPERSAND "&"
%token  <y_noval>       AMPERSAND_AMPERSAND "&&"
%token  <y_noval>       AT "@"
%token  <y_noval>       BANG "!"
%token  <y_noval>       BANG_EQ "!="
%token  <y_noval>       BAR "|"
%token  <y_noval>       BAR_BAR "||"
%token  <y_noval>       CARET "^"
%token  <y_noval>       COLON ":"
%token  <y_noval>       COLON_COLON "::"
%token  <y_noval>       COMMA ","
%token  <y_noval>       DOLLAR "$"
%token  <y_noval>       ELLIPSES "..."
%token  <y_noval>       EO_ARGS
%token  <y_noval>       EOL
%token  <y_noval>       EQ "="
%token  <y_noval>       EQ_EQ "=="
%token  <y_noval>       FORMAT "format"
%token  <y_noval>       GT ">"
%token  <y_noval>       GT_EQ ">="
%token  <y_noval>       GT_GT ">>"
%token  <y_noval>       HASH "#"
%token  <y_noval>       HASH_HASH "##"
%token  <y_sval>        ID
%token  <y_sval>        ID_LPAREN                 /* only on #define */
%token  <y_noval>       IMPLICIT "implicit"
%token  <y_noval>       LBRACKET "["
%token  <y_noval>       LPAREN "("
%token  <y_noval>       LPAREN_SLASH "(/"
%token  <y_noval>       LT "<"
%token  <y_noval>       LT_EQ "<="
%token  <y_noval>       LT_LT "<<"
%token  <y_noval>       MINUS "-"
%token  <y_noval>       PERCENT "%"
%token  <y_noval>       PERIOD "."
%token  <y_noval>       PERIOD_AND_PERIOD ".and."
%token  <y_noval>       PERIOD_EQ_PERIOD ".eq."
%token  <y_noval>       PERIOD_EQV_PERIOD ".eqv."
%token  <y_noval>       PERIOD_FALSE_PERIOD ".false."
%token  <y_noval>       PERIOD_GE_PERIOD ".ge."
%token  <y_noval>       PERIOD_GT_PERIOD ".gt."
%token  <y_sval>        PERIOD_ID_PERIOD       /* user-defined operator */
%token  <y_noval>       PERIOD_LE_PERIOD ".le."
%token  <y_noval>       PERIOD_LT_PERIOD ".lt."
%token  <y_noval>       PERIOD_NE_PERIOD ".ne."
%token  <y_noval>       PERIOD_NEQV_PERIOD ".neqv."
%token  <y_noval>       PERIOD_NIL_PERIOD "nil."
%token  <y_noval>       PERIOD_NOT_PERIOD ".not."
%token  <y_noval>       PERIOD_OR_PERIOD ".or."
%token  <y_noval>       PERIOD_TRUE_PERIOD ".true."
%token  <y_noval>       PLUS "+"
%token  <y_noval>       POINTS "=>"
%token  <y_noval>       QUESTION "?"
%token  <y_noval>       RBRACKET "]"
%token  <y_noval>       REAL_NUMBER
%token  <y_noval>       RPAREN ")"
%token  <y_noval>       SEMICOLON ";"
%token  <y_noval>       SLASH "/"
%token  <y_noval>       SLASH_EQ "/="
%token  <y_noval>       SLASH_RPAREN "/)"
%token  <y_noval>       SLASH_SLASH "//"
%token  <y_sval>        STRING
%token  <y_noval>       TILDE "~"
%token  <y_noval>       TIMES "*"
%token  <y_noval>       TIMES_TIMES "**"
%token  <y_noval>       UNDERSCORE  "_"           /* for _KIND, not ID */
%token  <y_ival>        WHOLE_NUMBER

%token  <y_sval>        UND_UND_FILE "__FILE__"
%token  <y_sval>        UND_UND_LINE "__LINE__"
%token  <y_sval>        UND_UND_DATE "__DATE__"
%token  <y_sval>        UND_UND_TIME "__TIME__"
%token  <y_sval>        UND_UND_STDFORTRAN "__STDFORTRAN__"
%token  <y_sval>        UND_UND_STDFORTRAN_VERSION "__STDFORTRAN_VERSION__"
%token  <y_sval>        UND_UND_VA_ARGS "VA_ARGS"
%token  <y_sval>        UND_UND_VA_OPT "VA_OPT"

%type   <y_env>         ExecutableProgram
%type   <y_scope>       CommandLineDefinitionList
%type   <y_env>         GroupPartList
%type   <y_env>         GroupPart
%type   <y_ast>         IfSection
%type   <y_ast>         ElifGroupList
%type   <y_ast>         ElseGroup
%type   <y_noval>       EndifLine
%type   <y_env>         ControlLine
%type   <y_env>         IncludeControlLine
%type   <y_env>         DefineIdControlLine
%type   <y_env>         DefineFunctionControlLine
%type   <y_tokens>      LambdaList
%type   <y_tokens>      IDList
%type   <y_loc>         LineControlLine
%type   <y_env>         ErrorControlLine
%type   <y_env>         WarningControlLine
%type   <y_env>         PragmaControlLine
%type   <y_env>         NonDirective
%type   <y_tokens>      ReplacementText
%type   <y_token>       ReplacementToken
%type   <y_tokens>      PPTokenList
%type   <y_token>       PPToken
%type   <y_tokens>      PPTokenListExceptCommaRParen
%type   <y_token>       PPTokenExceptCommaRParen
%type   <y_tokens>      FortranTokenList
%type   <y_token>       FortranToken
%type   <y_token>       FortranTokenExceptCommaRParen
%type   <y_token>       FortranTokenExceptFormatImplicit
%type   <y_token>       FortranTokenAnywhere
%type   <y_tokens>      FortranTokenListExceptFormatImplicit
%type   <y_token>       CPPToken
%type   <y_ast>         Expression
%type   <y_token>       EquivOp
%type   <y_ast>         ConditionalExpr
%type   <y_ast>         LogicalOrExpr
%type   <y_token>       OrOp
%type   <y_ast>         LogicalAndExpr
%type   <y_token>       AndOp
%type   <y_ast>         InclusiveOrExpr
%type   <y_ast>         ExclusiveOrExpr
%type   <y_ast>         AndExpr
%type   <y_ast>         EqualityExpr
%type   <y_token>       EqualityOp
%type   <y_ast>         RelationalExpr
%type   <y_token>       RelationalOp
%type   <y_ast>         ShiftExpr
%type   <y_token>       ShiftOp
%type   <y_ast>         CharacterExpr
%type   <y_ast>         AdditiveExpr
%type   <y_token>       AddOp
%type   <y_ast>         MultiplicativeExpr
%type   <y_token>       MultOp
%type   <y_ast>         PowerExpr
%type   <y_ast>         UnaryExpr
%type   <y_token>       UnaryOp
%type   <y_ast>         PostfixExpr
%type   <y_ast>         ActualArgumentList
%type   <y_ast>         PrimaryExpr
%type   <y_token>       PredefinedIdentifier
%type   <y_tokens>      FortranSourceLine

%%


ExecutableProgram:
      CommandLineDefinitionList EO_ARGS {
          $$ = new_env($1);
      };
ExecutableProgram: ExecutableProgram GroupPart {
            $$ = update_env($1, $2);
      };

CommandLineDefinitionList:
      %empty {
          $$ = create_empty_scope();
      };
CommandLineDefinitionList:
       CommandLineDefinitionList HASH_INCLUDE STRING EOL {
          $$ = add_path($1, $3);
      };
CommandLineDefinitionList:
      CommandLineDefinitionList HASH_DEFINE ID ReplacementText EOL {
          $$ = add_defn($1, $3, $4);
      };
CommandLineDefinitionList:
      CommandLineDefinitionList HASH_DEFINE ID_LPAREN LambdaList RPAREN
            ReplacementText EOL {
          $$ = add_defn_args($1, $3, $4, $6);
      };
CommandLineDefinitionList:
      CommandLineDefinitionList HASH_UNDEF ID EOL {
          $$ = rm_defn($1, $3);
      };

/* A GroupPart is some directive, or some Fortran text. */
GroupPartList: GroupPart;
GroupPartList: GroupPartList GroupPart;

GroupPart: IfSection {
               $$ = eval($1, cur_env);
      };
GroupPart: ControlLine {
               $$ = cur_env;
               $$.y_loc = $1;
      };
GroupPart: NonDirective {
               $$ = cur_env;
      };
GroupPart: FortranSourceLine {
               $$ = cur_env;
               $$.e_tokens =
                   append_token_list(cur_env.e_tokens,
                                     expand_tokens(cur_env, $1.y_tokens));
      };

/* TODO: Need to break this up to keep IF value available.
 * Probably need to turn these into an AST of
 * some kind and evaluate accordingly.
 */
IfSection: HASH_IF Expression EOL GroupPartList EndifLine {
               $$ = new_ast(HASH_IF, $1.a_loc, $2, NULL, NULL);
      };
IfSection: HASH_IF Expression EOL GroupPartList ElseGroup EndifLine {
               $$ = new_ast(HASH_IF, $1.a_loc, $2, NULL, $5);
      };
IfSection: HASH_IF Expression EOL GroupPartList ElifGroupList EndifLine {
               $$ = new_ast(HASH_IF, $1.a_loc, $2, $5, NULL);
      };
IfSection: HASH_IF Expression EOL GroupPartList ElifGroupList
       ElseGroup EndifLine {
               $$ = new_ast(HASH_IF, $1.a_loc, $2, $5, $6);
      };
IfSection: HASH_IFDEF ID EOL GroupPartList EndifLine {
               $$ = new_ast(HASH_IFDEF, $1.a_loc, new_ast(ID, $2, $3);
      };
IfSection: HASH_IFNDEF ID EOL GroupPartList EndifLine {
               $$ = new_ast(HASH_IFNDEF, $1.a_loc,
                            new_ast(ID, $2, $3), NULL, NULL;
      };
/* These are constructed such that we need depth-first eval :-( */
ElifGroupList: HASH_ELIF Expression EOL GroupPartList {
                   $$ = new_ast(HASH_ELIF, $1.a_loc, $2, $4, NULL);
      };
ElifGroupList: ElifGroupList HASH_ELIF Expression EOL GroupPartList {
                   $$ = new_ast(HASH_ELIF, $1.a_loc, $3, $5, NULL);
      };

ElseGroup: HASH_ELSE EOL GroupPartList {
                   $$ = new_ast(HASH_ELSE, $1.loc, $3, NULL, NULL);
      };

EndifLine: HASH_ENDIF EOL;

ControlLine: IncludeControlLine;        /* TODO */
ControlLine: DefineIdControlLine;        /* TODO */
ControlLine: DefineFunctionControlLine;        /* TODO */
ControlLine: LineControlLine;        /* TODO */
ControlLine: ErrorControlLine;        /* TODO */
ControlLine: WarningControlLine;        /* TODO */
ControlLine: PragmaControlLine;        /* TODO */

/* TODO Add PPTokens as alternative. */
IncludeControlLine: HASH_INCLUDE STRING EOL;        /* TODO */

DefineIdControlLine: HASH_DEFINE ID EOL;        /* TODO */
DefineIdControlLine: HASH_DEFINE ID PPTokenList EOL;        /* TODO */

/*
 * Parameter lists on macro functions are comma-separated
 * identifiers.
 */
DefineFunctionControlLine: HASH_DEFINE ID_LPAREN LambdaList RPAREN
      EOL;        /* TODO */
DefineFunctionControlLine: HASH_DEFINE ID_LPAREN LambdaList RPAREN
      ReplacementText EOL;        /* TODO */

LambdaList: %empty;        /* TODO */
LambdaList: ELLIPSES;        /* TODO */
LambdaList: IDList;        /* TODO */
LambdaList: IDList COMMA ELLIPSES;        /* TODO */

IDList: ID;        /* TODO */
IDList: IDList COMMA ID;        /* TODO */

LineControlLine: HASH_LINE STRING WHOLE_NUMBER EOL;        /* TODO */
LineControlLine: HASH_LINE WHOLE_NUMBER EOL;        /* TODO */

ErrorControlLine: HASH_ERROR STRING EOL;        /* TODO */

WarningControlLine: HASH_WARNING STRING EOL;        /* TODO */

PragmaControlLine: HASH_PRAGMA PPTokenList EOL;        /* TODO */

NonDirective: HASH PPTokenList EOL {
                  $$ = $2;
      };

ReplacementText: ReplacementToken {
                   $$ = append_token(new_token_list(), $1);
      };
ReplacementText: ReplacementText ReplacementToken {
                   $$ = append_token($1, $2);
      };

/*
 * '#' and '##' operators can only appear in the replacement
 * text in #define directives.
 */
ReplacementToken: PPToken;
ReplacementToken: HASH;
ReplacementToken: HASH_HASH;

PPTokenList: PPToken {
                   $$ = append_token(new_token_list(), $1);
      };
PPTokenList: PPTokenList PPToken {
                   $$ = append_token($1, $2);
      };

PPToken: FortranToken;
PPToken: CPPToken;

PPTokenListExceptCommaRParen: PPTokenExceptCommaRParen {
                   $$ = append_token(new_token_list(), $1);
      };
PPTokenListExceptCommaRParen: PPTokenListExceptCommaRParen
      PPTokenExceptCommaRParen {
                   $$ = append_token($1, $2);
      };

PPTokenExceptCommaRParen: FortranTokenExceptCommaRParen;
PPTokenExceptCommaRParen: CPPToken;

/*
 * This should include every token that the tokenizer
 * could recognize. The tokenizer has to do some recognition
 * of Fortran operators (such as .AND.) and places where
 * preprocessing expansion should not * occur (such as FORMAT
 * and IMPLICIT).
 */

FortranTokenList: FortranToken {
                   $$ = append_token(new_token_list(), $1);
      };
FortranTokenList: FortranTokenList FortranToken {
                   $$ = append_token($1, $2);
      };

FortranToken: FortranTokenAnywhere;
FortranToken: COMMA;
FortranToken: RPAREN;
FortranToken: FORMAT;
FortranToken: IMPLICIT;

FortranTokenExceptCommaRParen: FortranTokenAnywhere;
FortranTokenExceptCommaRParen: FORMAT;
FortranTokenExceptCommaRParen: IMPLICIT;

FortranTokenExceptFormatImplicit: FortranTokenAnywhere;
FortranTokenExceptFormatImplicit: COMMA;
FortranTokenExceptFormatImplicit: RPAREN;

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
    | WHOLE_NUMBER;

FortranTokenListExceptFormatImplicit: FortranTokenExceptFormatImplicit {
                   $$ = append_token(new_token_list(), $1);
      };
FortranTokenListExceptFormatImplicit: FortranTokenListExceptFormatImplicit
      FortranTokenExceptFormatImplicit {
                   $$ = append_token($1, $2);
      };

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
Expression: Expression EquivOp ConditionalExpr;        /* TODO */

EquivOp: PERIOD_EQV_PERIOD;
EquivOp: PERIOD_NEQV_PERIOD;

ConditionalExpr: LogicalOrExpr QUESTION Expression COLON
      ConditionalExpr;        /* TODO */
ConditionalExpr: LogicalOrExpr;

LogicalOrExpr: LogicalAndExpr;
LogicalOrExpr: LogicalOrExpr OrOp LogicalAndExpr;        /* TODO */

OrOp: BAR_BAR;
OrOp: PERIOD_OR_PERIOD;

LogicalAndExpr: InclusiveOrExpr;
LogicalAndExpr: LogicalAndExpr AndOp InclusiveOrExpr;        /* TODO */

AndOp: AMPERSAND_AMPERSAND;
AndOp: PERIOD_AND_PERIOD;

InclusiveOrExpr: ExclusiveOrExpr;
InclusiveOrExpr: InclusiveOrExpr BAR ExclusiveOrExpr;        /* TODO */

ExclusiveOrExpr: AndExpr;
ExclusiveOrExpr: ExclusiveOrExpr CARET AndExpr;        /* TODO */

AndExpr: EqualityExpr;
AndExpr: AndExpr AMPERSAND EqualityExpr;        /* TODO */

EqualityExpr: RelationalExpr;        /* TODO */
EqualityExpr: EqualityExpr EqualityOp RelationalExpr;        /* TODO */

EqualityOp: PERIOD_EQ_PERIOD;
EqualityOp: PERIOD_NE_PERIOD;
EqualityOp: EQ_EQ;
EqualityOp: SLASH_EQ;
EqualityOp: BANG_EQ;

RelationalExpr: ShiftExpr;
RelationalExpr: RelationalExpr RelationalOp ShiftExpr;        /* TODO */

RelationalOp: PERIOD_LE_PERIOD;
RelationalOp: PERIOD_LT_PERIOD;
RelationalOp: PERIOD_GE_PERIOD;
RelationalOp: PERIOD_GT_PERIOD;
RelationalOp: LT;
RelationalOp: GT;
RelationalOp: LT_EQ;
RelationalOp: GT_EQ;

ShiftExpr: CharacterExpr;
ShiftExpr: ShiftExpr ShiftOp CharacterExpr;        /* TODO */

ShiftOp: LT_LT;
ShiftOp: GT_GT;

CharacterExpr: AdditiveExpr;
CharacterExpr: CharacterExpr SLASH_SLASH AdditiveExpr;        /* TODO */

AdditiveExpr: MultiplicativeExpr;
AdditiveExpr: AdditiveExpr AddOp MultiplicativeExpr;        /* TODO */

AddOp: PLUS;
AddOp: MINUS;

MultiplicativeExpr: PowerExpr;
MultiplicativeExpr: MultiplicativeExpr MultOp PowerExpr;        /* TODO */

MultOp: TIMES;
MultOp: SLASH;
MultOp: PERCENT;

PowerExpr: UnaryExpr;
PowerExpr: UnaryExpr TIMES_TIMES PowerExpr;        /* TODO */

UnaryExpr: UnaryOp PostfixExpr;        /* TODO */
UnaryExpr: PostfixExpr;

UnaryOp: PLUS;
UnaryOp: MINUS;
UnaryOp: PERIOD_NOT_PERIOD;
UnaryOp: BANG;
UnaryOp: TILDE;

PostfixExpr: PrimaryExpr;
PostfixExpr: ID LPAREN RPAREN;        /* TODO */
PostfixExpr: ID LPAREN ActualArgumentList RPAREN;        /* TODO */

/* TODO: Really this should be properly nested parenthesized lists */
ActualArgumentList: PPTokenListExceptCommaRParen;        /* TODO */
ActualArgumentList: ActualArgumentList COMMA
      PPTokenListExceptCommaRParen;        /* TODO */

/* Real numbers aren't allowed in conditional explessions */
PrimaryExpr: WHOLE_NUMBER;        /* TODO */
PrimaryExpr: ID;        /* TODO */
PrimaryExpr: PERIOD_FALSE_PERIOD;        /* TODO */
PrimaryExpr: PERIOD_NIL_PERIOD;        /* TODO */
PrimaryExpr: PERIOD_TRUE_PERIOD;        /* TODO */
PrimaryExpr: LPAREN Expression RPAREN;        /* TODO */
PrimaryExpr: PredefinedIdentifier;        /* TODO */

/* Identifiers known to the preprocessor (such as __FILE__) */
PredefinedIdentifier: UND_UND_FILE;        /* TODO */
PredefinedIdentifier: UND_UND_LINE;        /* TODO */
PredefinedIdentifier: UND_UND_DATE;        /* TODO */
PredefinedIdentifier: UND_UND_TIME;        /* TODO */
PredefinedIdentifier: UND_UND_STDFORTRAN;        /* TODO */
PredefinedIdentifier: UND_UND_STDFORTRAN_VERSION;        /* TODO */
PredefinedIdentifier: UND_UND_VA_ARGS;        /* TODO */
PredefinedIdentifier: UND_UND_VA_OPT;        /* TODO */

FortranSourceLine: EOL {
                   $$ = append_token(new_token_list(), $1);
      };
FortranSourceLine: FORMAT FortranTokenList EOL {
                       $$ = append_token(new_token_list(), $1)
                       $$ = append_token_list($$, $2);
                       $$ = append_token($$, $3);
      };
FortranSourceLine: IMPLICIT FortranTokenList EOL {
                       $$ = append_token(new_token_list(), $1)
                       $$ = append_token_list($$, $2);
                       $$ = append_token($$, $3);
      };
FortranSourceLine: FortranTokenListExceptFormatImplicit EOL {
                   $$ = append_token($1, $2);
      };
