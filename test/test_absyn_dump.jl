@testset "absynDump pretty-printing" begin
  using Absyn
  using MetaModelica

  @testset "dumpPath" begin
    @test Absyn.dumpPath(IDENT("Real")) == "Real"
    @test Absyn.dumpPath(QUALIFIED("Modelica", IDENT("SIunits"))) == "Modelica.SIunits"
    @test Absyn.dumpPath(FULLYQUALIFIED(IDENT("Real"))) == ".Real"
  end

  @testset "dumpCref" begin
    @test Absyn.dumpCref(CREF_IDENT("x", nil)) == "x"
    @test Absyn.dumpCref(CREF_IDENT("x", list(SUBSCRIPT(INTEGER(1))))) == "x[1]"
    @test Absyn.dumpCref(CREF_QUAL("a", nil, CREF_IDENT("b", nil))) == "a.b"
    @test Absyn.dumpCref(CREF_QUAL("a", list(SUBSCRIPT(INTEGER(1))), CREF_IDENT("b", nil))) == "a[1].b"
    @test Absyn.dumpCref(CREF_FULLYQUALIFIED(CREF_IDENT("x", nil))) == ".x"
    @test Absyn.dumpCref(WILD()) == "_"
    @test Absyn.dumpCref(ALLWILD()) == "__"
  end

  @testset "dumpSubscript" begin
    @test Absyn.dumpSubscript(NOSUB()) == ":"
    @test Absyn.dumpSubscript(SUBSCRIPT(INTEGER(3))) == "3"
  end

  @testset "dumpOperator" begin
    @test Absyn.dumpOperator(ADD()) == " + "
    @test Absyn.dumpOperator(SUB()) == " - "
    @test Absyn.dumpOperator(MUL()) == "*"
    @test Absyn.dumpOperator(DIV()) == "/"
    @test Absyn.dumpOperator(POW()) == "^"
    @test Absyn.dumpOperator(UMINUS()) == "-"
    @test Absyn.dumpOperator(AND()) == " and "
    @test Absyn.dumpOperator(OR()) == " or "
    @test Absyn.dumpOperator(NOT()) == "not "
    @test Absyn.dumpOperator(LESS()) == " < "
    @test Absyn.dumpOperator(EQUAL()) == " == "
  end

  @testset "dumpExp basics" begin
    @test Absyn.dumpExp(INTEGER(42)) == "42"
    @test Absyn.dumpExp(REAL("3.14")) == "3.14"
    @test Absyn.dumpExp(STRING("hello")) == "\"hello\""
    @test Absyn.dumpExp(BOOL(true)) == "true"
    @test Absyn.dumpExp(BOOL(false)) == "false"
    @test Absyn.dumpExp(END()) == "end"
  end

  @testset "dumpExp CREF" begin
    @test Absyn.dumpExp(CREF(CREF_IDENT("x", nil))) == "x"
    @test Absyn.dumpExp(CREF(CREF_QUAL("a", nil, CREF_IDENT("b", nil)))) == "a.b"
  end

  @testset "dumpExp BINARY/UNARY" begin
    @test Absyn.dumpExp(BINARY(INTEGER(1), ADD(), INTEGER(2))) == "1 + 2"
    @test Absyn.dumpExp(UNARY(UMINUS(), CREF(CREF_IDENT("a", nil)))) == "-a"
    @test Absyn.dumpExp(BINARY(UNARY(UMINUS(), CREF(CREF_IDENT("a", nil))), MUL(), CREF(CREF_IDENT("x", nil)))) == "-a*x"
  end

  @testset "dumpExp CALL" begin
    local der_x = CALL(CREF_IDENT("der", nil), FUNCTIONARGS(list(CREF(CREF_IDENT("x", nil))), nil), nil)
    @test Absyn.dumpExp(der_x) == "der(x)"

    local sin_x = CALL(CREF_IDENT("sin", nil), FUNCTIONARGS(list(CREF(CREF_IDENT("x", nil))), nil), nil)
    @test Absyn.dumpExp(sin_x) == "sin(x)"
  end

  @testset "dumpExp RANGE" begin
    @test Absyn.dumpExp(RANGE(INTEGER(1), nothing, INTEGER(10))) == "1:10"
    @test Absyn.dumpExp(RANGE(INTEGER(1), SOME(INTEGER(2)), INTEGER(10))) == "1:2:10"
  end

  @testset "dumpExp TUPLE/ARRAY" begin
    @test Absyn.dumpExp(TUPLE(list(INTEGER(1), INTEGER(2)))) == "(1, 2)"
    @test Absyn.dumpExp(ARRAY(list(INTEGER(1), INTEGER(2), INTEGER(3)))) == "{1, 2, 3}"
  end

  @testset "dumpExp CONS/LIST" begin
    @test Absyn.dumpExp(CONS(INTEGER(1), CREF(CREF_IDENT("rest", nil)))) == "1 :: rest"
    @test Absyn.dumpExp(LIST(list(INTEGER(1), INTEGER(2)))) == "{1, 2}"
  end

  @testset "dumpExp AS/DOT" begin
    @test Absyn.dumpExp(AS("x", INTEGER(1))) == "x as 1"
    @test Absyn.dumpExp(DOT(CREF(CREF_IDENT("a", nil)), CREF(CREF_IDENT("b", nil)))) == "a.b"
  end

  @testset "dumpFunctionArgs" begin
    @test Absyn.dumpFunctionArgs(FUNCTIONARGS(list(INTEGER(1), INTEGER(2)), nil)) == "1, 2"
    @test Absyn.dumpFunctionArgs(FUNCTIONARGS(nil, list(NAMEDARG("x", INTEGER(1))))) == "x = 1"
    @test Absyn.dumpFunctionArgs(FUNCTIONARGS(list(INTEGER(1)), list(NAMEDARG("y", INTEGER(2))))) == "1, y = 2"
  end

  @testset "dumpTypeSpec" begin
    @test Absyn.dumpTypeSpec(TPATH(IDENT("Real"), nothing)) == "Real"
    @test Absyn.dumpTypeSpec(TPATH(QUALIFIED("Modelica", IDENT("SIunits")), nothing)) == "Modelica.SIunits"
    @test Absyn.dumpTypeSpec(TCOMPLEX(IDENT("List"), list(TPATH(IDENT("Integer"), nothing)), nothing)) == "List<Integer>"
  end

  @testset "dumpDirection" begin
    @test Absyn.dumpDirection(BIDIR()) == ""
    @test Absyn.dumpDirection(INPUT()) == "input "
    @test Absyn.dumpDirection(OUTPUT()) == "output "
  end
end
