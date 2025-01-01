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

    token_t token(yytoken_kind_t t, YYLTYPE loc, YYSTYPE val);

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
        yytoken_kind_t    a_op;
        YYLTYPE           a_loc;
        YYSTYPE           a_v1, a_v2, a_v3;
    } ast_t;

    ast_t *new_ast(token_t op, YYLTYPE loc,
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

%token  <y_token>       HASH_DEFINE "#define"
%token  <y_token>       HASH_ELIF "#elif"
%token  <y_token>       HASH_ELSE "#else"
%token  <y_token>       HASH_ENDIF "#endif"
%token  <y_token>       HASH_ERROR "#error"
%token  <y_token>       HASH_IF "#if"
%token  <y_token>       HASH_IFDEF "#ifdef"
%token  <y_token>       HASH_IFNDEF "#ifndef"
%token  <y_token>       HASH_INCLUDE "#include"
%token  <y_token>       HASH_LINE "#line"
%token  <y_token>       HASH_PRAGMA "#pragma"
%token  <y_token>       HASH_UNDEF "#undef"
%token  <y_token>       HASH_WARNING "#warning"

%token  <y_token>       AMPERSAND "&"
%token  <y_token>       AMPERSAND_AMPERSAND "&&"
%token  <y_token>       AT "@"
%token  <y_token>       BANG "!"
%token  <y_token>       BANG_EQ "!="
%token  <y_token>       BAR "|"
%token  <y_token>       BAR_BAR "||"
%token  <y_token>       CARET "^"
%token  <y_token>       COLON ":"
%token  <y_token>       COLON_COLON "::"
%token  <y_token>       COMMA ","
%token  <y_token>       DOLLAR "$"
%token  <y_token>       ELLIPSES "..."
%token  <y_token>       EO_ARGS
%token  <y_token>       EOL
%token  <y_token>       EQ "="
%token  <y_token>       EQ_EQ "=="
%token  <y_token>       FORMAT "format"
%token  <y_token>       GT ">"
%token  <y_token>       GT_EQ ">="
%token  <y_token>       GT_GT ">>"
%token  <y_token>       HASH "#"
%token  <y_token>       HASH_HASH "##"
%token  <y_token>       HASH_INCLUDE_STRING
%token  <y_token>       HASH_INCLUDE_BRACKETED_STRING
%token  <y_token>       ID
%token  <y_token>       ID_LPAREN                 /* only on #define */
%token  <y_token>       IMPLICIT "implicit"
%token  <y_token>       LBRACKET "["
%token  <y_token>       LPAREN "("
%token  <y_token>       LPAREN_SLASH "(/"
%token  <y_token>       LT "<"
%token  <y_token>       LT_EQ "<="
%token  <y_token>       LT_LT "<<"
%token  <y_token>       MINUS "-"
%token  <y_token>       PERCENT "%"
%token  <y_token>       PERIOD "."
%token  <y_token>       PERIOD_AND_PERIOD ".and."
%token  <y_token>       PERIOD_EQ_PERIOD ".eq."
%token  <y_token>       PERIOD_EQV_PERIOD ".eqv."
%token  <y_token>       PERIOD_FALSE_PERIOD ".false."
%token  <y_token>       PERIOD_GE_PERIOD ".ge."
%token  <y_token>       PERIOD_GT_PERIOD ".gt."
%token  <y_token>       PERIOD_ID_PERIOD       /* user-defined operator */
%token  <y_token>       PERIOD_LE_PERIOD ".le."
%token  <y_token>       PERIOD_LT_PERIOD ".lt."
%token  <y_token>       PERIOD_NE_PERIOD ".ne."
%token  <y_token>       PERIOD_NEQV_PERIOD ".neqv."
%token  <y_token>       PERIOD_NIL_PERIOD "nil."
%token  <y_token>       PERIOD_NOT_PERIOD ".not."
%token  <y_token>       PERIOD_OR_PERIOD ".or."
%token  <y_token>       PERIOD_TRUE_PERIOD ".true."
%token  <y_token>       PLUS "+"
%token  <y_token>       POINTS "=>"
%token  <y_token>       QUESTION "?"
%token  <y_token>       RBRACKET "]"
%token  <y_token>       REAL_NUMBER
%token  <y_token>       RPAREN ")"
%token  <y_token>       SEMICOLON ";"
%token  <y_token>       SLASH "/"
%token  <y_token>       SLASH_EQ "/="
%token  <y_token>       SLASH_RPAREN "/)"
%token  <y_token>       SLASH_SLASH "//"
%token  <y_token>       STRING
%token  <y_token>       TILDE "~"
%token  <y_token>       TIMES "*"
%token  <y_token>       TIMES_TIMES "**"
%token  <y_token>       UNDERSCORE  "_"           /* for _KIND, not ID */
%token  <y_token>       WHOLE_NUMBER

%token  <y_token>       UND_UND_FILE "__FILE__"
%token  <y_token>       UND_UND_LINE "__LINE__"
%token  <y_token>       UND_UND_DATE "__DATE__"
%token  <y_token>       UND_UND_TIME "__TIME__"
%token  <y_token>       UND_UND_STDFORTRAN "__STDFORTRAN__"
%token  <y_token>       UND_UND_STDFORTRAN_VERSION "__STDFORTRAN_VERSION__"
%token  <y_token>       UND_UND_VA_ARGS "VA_ARGS"
%token  <y_token>       UND_UND_VA_OPT "VA_OPT"

/* Tokens only used for AST operations */
%token  <y_token>       PROGRAM
%token  <y_token>       AND_THEN
%token  <y_token>       EXPAND
%token  <y_token>       HASH_INCLUDE_EVAL

%type   <y_ast>         ExecutableProgram
%type   <y_ast>         CommandLineDefinitionList
%type   <y_ast>         GroupPartList
%type   <y_ast>         GroupPart
%type   <y_ast>         IfSection
%type   <y_ast>         ElifGroupList
%type   <y_ast>         ElseGroup
%type   <y_token>       EndifLine
%type   <y_ast>         ControlLine
%type   <y_ast>         IncludeControlLine
%type   <y_ast>         DefineIdControlLine
%type   <y_ast>         DefineFunctionControlLine
%type   <y_tokens>      LambdaList
%type   <y_tokens>      IDList
%type   <y_ast>         LineControlLine
%type   <y_ast>         ErrorControlLine
%type   <y_ast>         WarningControlLine
%type   <y_ast>         PragmaControlLine
%type   <y_ast>         NonDirective
%type   <y_tokens>      ReplacementText
%type   <y_token>       ReplacementToken
%type   <y_tokens>      PPTokenList
%type   <y_token>       PPToken
%type   <y_token>       PPTokenExceptParensComma
%type   <y_tokens>      PPTokenListBalancedParens
%type   <y_tokens>      FortranTokenList
%type   <y_token>       FortranToken
%type   <y_token>       FortranTokenExceptParensComma
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
%type   <y_ast>         PredefinedIdentifier
%type   <y_tokens>      FortranSourceLine

%%


ExecutableProgram: CommandLineDefinitionList EO_ARGS {
          $$ = new_ast(PROGRAM, $1->a_loc, $1, NULL, NULL);
      };
ExecutableProgram: ExecutableProgram GroupPart {
          $$ = new_ast(AND_THEN, $2->a_loc, $1, $2, NULL);
      };

CommandLineDefinitionList:
      %empty {
          $$ = NULL;
      };
CommandLineDefinitionList:
       CommandLineDefinitionList HASH_INCLUDE STRING EOL {
           $$ = new_ast(AND_THEN, $2.t_loc, $1,
                        new_ast(HASH_INCLUDE, $3.loc, $3, NULL, NULL),
                        NULL);
      };
CommandLineDefinitionList:
      CommandLineDefinitionList HASH_DEFINE ID EOL {
           $$ = new_ast(AND_THEN, $2.t_loc, $1,
                        new_ast(HASH_DEFINE, $3.t_loc, NULL, NULL, NULL),
                        NULL);
      };
CommandLineDefinitionList:
      CommandLineDefinitionList HASH_DEFINE ID ReplacementText EOL {
           $$ = new_ast(AND_THEN, $4.a_loc, $1,
                        new_ast(HASH_DEFINE, $3.t_loc, $4, NULL, $4),
                        NULL);
      };
CommandLineDefinitionList:
      CommandLineDefinitionList HASH_DEFINE ID_LPAREN LambdaList RPAREN
            ReplacementText EOL {
           $$ = new_ast(AND_THEN, $4.a_loc, $1,
                        new_ast(HASH_DEFINE, $3.t_loc, $4, $3, $4),
                        NULL);
      };
CommandLineDefinitionList:
      CommandLineDefinitionList HASH_UNDEF ID EOL {
           $$ = new_ast(AND_THEN, $4.loc, $1,
                        new_ast(HASH_UNDEF, $3.loc, $3, NULL, NULL),
                        NULL);
      };

/* A GroupPart is some directive, or some Fortran text. */
GroupPartList: GroupPart;
GroupPartList: GroupPartList GroupPart {
           $$ = new_ast(AND_THEN, $2.loc, $1, $2, NULL);
      };

GroupPart: IfSection {
              $$ = $1;
      };
GroupPart: ControlLine {
              $$ = $1;
      };
GroupPart: NonDirective {
              $$ = $1;
      };
GroupPart: FortranSourceLine {
               $$ = new_ast(EXPAND, $1.loc, $1);
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

ControlLine: IncludeControlLine;
ControlLine: DefineIdControlLine;
ControlLine: DefineFunctionControlLine;
ControlLine: LineControlLine;
ControlLine: ErrorControlLine;
ControlLine: WarningControlLine;
ControlLine: PragmaControlLine;

IncludeControlLine: HASH_INCLUDE HASH_INCLUDE_STRING EOL {
                   $$ = new_ast(HASH_INCLUDE, $1.loc,
                                STRING, $2, NULL);
      };
IncludeControlLine: HASH_INCLUDE HASH_INCLUDE_BRACKETED_STRING EOL {
                   $$ = new_ast(HASH_INCLUDE, $1.loc,
                                STRING, $2, NULL);
      };
IncludeControlLine: HASH_INCLUDE PPTokenList EOL {
                   $$ = new_ast(HASH_INCLUDE_EVAL, $1.loc,
                                PPTokenList, $2, NULL);
      };


DefineIdControlLine: HASH_DEFINE ID EOL {
                   $$ = new_ast(HASH_DEFINE, $1.loc, $2, NULL, NULL)
      };
DefineIdControlLine: HASH_DEFINE ID PPTokenList EOL {
                   $$ = new_ast(HASH_DEFINE, $1.loc, $2, NULL, $3);
      };

/*
 * Parameter lists on macro functions are comma-separated
 * identifiers.
 */
DefineFunctionControlLine: HASH_DEFINE ID_LPAREN LambdaList RPAREN
      EOL {
                   $$ = new_ast(HASH_DEFINE, $1.loc, $2, $3, NULL);
      };
DefineFunctionControlLine: HASH_DEFINE ID_LPAREN LambdaList RPAREN
      ReplacementText EOL {
                   $$ = new_ast(HASH_DEFINE, $1.loc, $2, $3, $5);
      };

LambdaList: %empty {
                $$ = NULL;
      };
LambdaList: ELLIPSES {
                   $$ = append_token(new_token_list(),
                                     token(ELLIPSES, $1.loc, 0));
      };
LambdaList: IDList {
                $$ = $1;
      };
LambdaList: IDList COMMA ELLIPSES{
                   $$ = append_token($1, token(ELLIPSES, $1.loc, 0));
      };

IDList: ID {
                $$ = append_token(new_token_list(), $1);
      };
IDList: IDList COMMA ID{
                $$ = append_token($3, $1);
      };

LineControlLine: HASH_LINE STRING WHOLE_NUMBER EOL {
                $$ = new_ast(HASH_LINE, $1.loc, $2, $3, NULL);
      };
LineControlLine: HASH_LINE WHOLE_NUMBER EOL {
                $$ = new_ast(HASH_LINE, $1.loc, NULL, $3, NULL);
      };

ErrorControlLine: HASH_ERROR STRING EOL {
                $$ = new_ast(HASH_ERROR, $1.loc, $2, NULL, NULL);
      };

WarningControlLine: HASH_WARNING STRING EOL {
                $$ = new_ast(HASH_WARNING, $1.loc, $2, NULL, NULL);
      };

PragmaControlLine: HASH_PRAGMA PPTokenList EOL {
                $$ = new_ast(HASH_PRAGMA, $1.loc, $2, NULL, NULL);
      };

NonDirective: HASH PPTokenList EOL {
                  $$ = new_ast(HASH, $1.loc, $2, NULL, NULL);
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

PPTokenExceptParensComma: FortranTokenExceptParensComma;
PPTokenExceptParensComma: CPPToken;


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
FortranToken: LPAREN;
FortranToken: RPAREN;
FortranToken: FORMAT;
FortranToken: IMPLICIT;

FortranTokenExceptParensComma: FortranTokenAnywhere;
FortranTokenExceptParensComma: FORMAT;
FortranTokenExceptParensComma: IMPLICIT;

FortranTokenExceptFormatImplicit: FortranTokenAnywhere;
FortranTokenExceptFormatImplicit: COMMA;
FortranTokenExceptFormatImplicit: LPAREN;
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
Expression: Expression EquivOp ConditionalExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
      };

EquivOp: PERIOD_EQV_PERIOD;
EquivOp: PERIOD_NEQV_PERIOD;

ConditionalExpr: LogicalOrExpr QUESTION Expression COLON
      ConditionalExpr {
                $$ = new_ast(QUESTION, $1.loc, $1, $3, $4);
          };
ConditionalExpr: LogicalOrExpr;

LogicalOrExpr: LogicalAndExpr;
LogicalOrExpr: LogicalOrExpr OrOp LogicalAndExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

OrOp: BAR_BAR;
OrOp: PERIOD_OR_PERIOD;

LogicalAndExpr: InclusiveOrExpr;
LogicalAndExpr: LogicalAndExpr AndOp InclusiveOrExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

AndOp: AMPERSAND_AMPERSAND;
AndOp: PERIOD_AND_PERIOD;

InclusiveOrExpr: ExclusiveOrExpr;
InclusiveOrExpr: InclusiveOrExpr BAR ExclusiveOrExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

ExclusiveOrExpr: AndExpr;
ExclusiveOrExpr: ExclusiveOrExpr CARET AndExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

AndExpr: EqualityExpr;
AndExpr: AndExpr AMPERSAND EqualityExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

EqualityExpr: RelationalExpr;        /* TODO */
EqualityExpr: EqualityExpr EqualityOp RelationalExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

EqualityOp: PERIOD_EQ_PERIOD;
EqualityOp: PERIOD_NE_PERIOD;
EqualityOp: EQ_EQ;
EqualityOp: SLASH_EQ;
EqualityOp: BANG_EQ;

RelationalExpr: ShiftExpr;
RelationalExpr: RelationalExpr RelationalOp ShiftExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

RelationalOp: PERIOD_LE_PERIOD;
RelationalOp: PERIOD_LT_PERIOD;
RelationalOp: PERIOD_GE_PERIOD;
RelationalOp: PERIOD_GT_PERIOD;
RelationalOp: LT;
RelationalOp: GT;
RelationalOp: LT_EQ;
RelationalOp: GT_EQ;

ShiftExpr: CharacterExpr;
ShiftExpr: ShiftExpr ShiftOp CharacterExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

ShiftOp: LT_LT;
ShiftOp: GT_GT;

CharacterExpr: AdditiveExpr;
CharacterExpr: CharacterExpr SLASH_SLASH AdditiveExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

AdditiveExpr: MultiplicativeExpr;
AdditiveExpr: AdditiveExpr AddOp MultiplicativeExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

AddOp: PLUS;
AddOp: MINUS;

MultiplicativeExpr: PowerExpr;
MultiplicativeExpr: MultiplicativeExpr MultOp PowerExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

MultOp: TIMES;
MultOp: SLASH;
MultOp: PERCENT;

PowerExpr: UnaryExpr;
PowerExpr: UnaryExpr TIMES_TIMES PowerExpr {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

UnaryExpr: PostfixExpr;
UnaryExpr: UnaryOp PostfixExpr {
                $$ = new_ast($1.t_token, $1.loc, $2, NULL, NULL);
          };

UnaryOp: PLUS;
UnaryOp: MINUS;
UnaryOp: PERIOD_NOT_PERIOD;
UnaryOp: BANG;
UnaryOp: TILDE;

PostfixExpr: PrimaryExpr;
PostfixExpr: ID LPAREN RPAREN {
                $$ = new_ast($2.t_token, $1.loc, $1, NULL, NULL);
          };
PostfixExpr: ID LPAREN ActualArgumentList RPAREN {
                $$ = new_ast($2.t_token, $1.loc, $1, $3, NULL);
          };

ActualArgumentList: PPTokenListBalancedParens {
                $$ = new_ast(COMMA, $1.loc, $1, NULL, NULL);
          };
ActualArgumentList: ActualArgumentList COMMA PPTokenListBalancedParens {
                $$ = new_ast(COMMA, $1.loc, $1, $3, NULL);
          };

PPTokenListBalancedParens: PPTokenExceptParensComma {
                $$ = cons_token($1 new_token_list());
          };
PPTokenListBalancedParens: LPAREN RPAREN {
                $$ = cons_token(LPAREN, cons_token(RPAREN, new_token_list()));
          };
PPTokenListBalancedParens: LPAREN PPTokenListBalancedParens RPAREN {
                $$ = cons_token(LPAREN, append_token(RPAREN, $2));
          };
PPTokenListBalancedParens: PPTokenListBalancedParens PPTokenExceptParensComma {
                $$ = append_token($1, $2);
          };
PPTokenListBalancedParens: PPTokenListBalancedParens LPAREN RPAREN {
                $$ = append_token(append_token($1, LPAREN), RPAREN);
          };
PPTokenListBalancedParens: PPTokenListBalancedParens LPAREN PPTokenListBalancedParens RPAREN {
                $$ = append_token_list(append_token($1, LPAREN), append_token($3, RPAREN));
          };

/* Real numbers aren't allowed in conditional explessions */
PrimaryExpr: WHOLE_NUMBER {
                $$ = new_ast($1.t_token, $1.loc, $1, NULL, NULL);
          };

PrimaryExpr: ID {
                $$ = new_ast($1.t_token, $1.loc, $1, NULL, NULL);
          };
PrimaryExpr: PERIOD_FALSE_PERIOD {
                $$ = new_ast($1.t_token, $1.loc, $1, NULL, NULL);
          };
PrimaryExpr: PERIOD_NIL_PERIOD {
                $$ = new_ast($1.t_token, $1.loc, $1, NULL, NULL);
          };
PrimaryExpr: PERIOD_TRUE_PERIOD {
                $$ = new_ast($1.t_token, $1.loc, $1, NULL, NULL);
          };
PrimaryExpr: LPAREN Expression RPAREN {
                $$ = $2;
          };
PrimaryExpr: PredefinedIdentifier;

/* Identifiers known to the preprocessor (such as __FILE__) */
PredefinedIdentifier: UND_UND_FILE {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };
PredefinedIdentifier: UND_UND_LINE {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };
PredefinedIdentifier: UND_UND_DATE {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };
PredefinedIdentifier: UND_UND_TIME {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };
PredefinedIdentifier: UND_UND_STDFORTRAN {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };
PredefinedIdentifier: UND_UND_STDFORTRAN_VERSION {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };
PredefinedIdentifier: UND_UND_VA_ARGS {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };
PredefinedIdentifier: UND_UND_VA_OPT {
                          $$ = new_ast(ID, $1.loc, $1, , NULL);
          };

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
