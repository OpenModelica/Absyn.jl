#=
  Modelica pretty-printing for Absyn types.
  Used by the Dump module for error messages in NFFrontEnd.
  Reference: AbsynDumpTpl.tpl from OMCompiler/Compiler/Template/
=#

# --- Path ---

function dumpPath(p::Path)::String
  @match p begin
    FULLYQUALIFIED(__) => "." * dumpPath(p.path)
    QUALIFIED(__) => p.name * "." * dumpPath(p.path)
    IDENT(__) => p.name
    _ => "<unknown path>"
  end
end

# --- ComponentRef ---

function dumpCref(cr::ComponentRef)::String
  @match cr begin
    CREF_QUAL(__) => cr.name * dumpSubscripts(cr.subscripts) * "." * dumpCref(cr.componentRef)
    CREF_IDENT(__) => cr.name * dumpSubscripts(cr.subscripts)
    CREF_FULLYQUALIFIED(__) => "." * dumpCref(cr.componentRef)
    WILD(__) => "_"
    ALLWILD(__) => "__"
    _ => "<unknown cref>"
  end
end

# --- Subscripts ---

function dumpSubscripts(subs)::String
  local lst = collect(subs)
  isempty(lst) && return ""
  "[" * join((dumpSubscript(s) for s in lst), ", ") * "]"
end

function dumpSubscript(sub::Subscript)::String
  @match sub begin
    NOSUB(__) => ":"
    SUBSCRIPT(__) => dumpExp(sub.subscript)
    _ => "<unknown subscript>"
  end
end

# --- Expression ---

function dumpExp(exp::Exp)::String
  @match exp begin
    INTEGER(__) => string(exp.value)
    REAL(__) => exp.value
    STRING(__) => "\"" * exp.value * "\""
    BOOL(__) => exp.value ? "true" : "false"
    CREF(__) => dumpCref(exp.componentRef)
    BINARY(__) => dumpExp(exp.exp1) * dumpOperator(exp.op) * dumpExp(exp.exp2)
    UNARY(__) => dumpOperator(exp.op) * dumpExp(exp.exp)
    LBINARY(__) => dumpExp(exp.exp1) * dumpOperator(exp.op) * dumpExp(exp.exp2)
    LUNARY(__) => dumpOperator(exp.op) * " " * dumpExp(exp.exp)
    RELATION(__) => dumpExp(exp.exp1) * dumpOperator(exp.op) * dumpExp(exp.exp2)
    IFEXP(__) => begin
      local s = "if " * dumpExp(exp.ifExp) * " then " * dumpExp(exp.trueBranch)
      for (c, b) in exp.elseIfBranch
        s = s * " elseif " * dumpExp(c) * " then " * dumpExp(b)
      end
      s * " else " * dumpExp(exp.elseBranch)
    end
    CALL(__) => begin
      local fn = dumpCref(exp.function_)
      local args = dumpFunctionArgs(exp.functionArgs)
      fn * "(" * args * ")"
    end
    PARTEVALFUNCTION(__) => "function " * dumpCref(exp.function_) * "(" * dumpFunctionArgs(exp.functionArgs) * ")"
    ARRAY(__) => "{" * join((dumpExp(e) for e in exp.arrayExp), ", ") * "}"
    MATRIX(__) => "[" * join((join((dumpExp(e) for e in row), ", ") for row in exp.matrix), "; ") * "]"
    RANGE(__) => begin
      local s = dumpExp(exp.start)
      if !isnothing(exp.step)
        s = s * ":" * dumpExp(exp.step.data)
      end
      s * ":" * dumpExp(exp.stop)
    end
    TUPLE(__) => "(" * join((dumpExp(e) for e in exp.expressions), ", ") * ")"
    END(__) => "end"
    CODE(__) => "\$Code(...)"
    AS(__) => exp.id * " as " * dumpExp(exp.exp)
    CONS(__) => dumpExp(exp.head) * " :: " * dumpExp(exp.rest)
    LIST(__) => "{" * join((dumpExp(e) for e in exp.exps), ", ") * "}"
    DOT(__) => dumpExp(exp.exp) * "." * dumpExp(exp.index)
    SUBSCRIPTED_EXP(__) => "(" * dumpExp(exp.exp) * ")" * dumpSubscripts(exp.subscripts)
    EXPRESSIONCOMMENT(__) => dumpExp(exp.exp)
    _ => "<unknown exp>"
  end
end

# --- Operator ---

function dumpOperator(op::Operator)::String
  @match op begin
    ADD(__) => " + "
    SUB(__) => " - "
    MUL(__) => "*"
    DIV(__) => "/"
    POW(__) => "^"
    UPLUS(__) => "+"
    UMINUS(__) => "-"
    ADD_EW(__) => " .+ "
    SUB_EW(__) => " .- "
    MUL_EW(__) => ".*"
    DIV_EW(__) => "./"
    POW_EW(__) => ".^"
    UPLUS_EW(__) => ".+"
    UMINUS_EW(__) => ".-"
    AND(__) => " and "
    OR(__) => " or "
    NOT(__) => "not "
    LESS(__) => " < "
    LESSEQ(__) => " <= "
    GREATER(__) => " > "
    GREATEREQ(__) => " >= "
    EQUAL(__) => " == "
    NEQUAL(__) => " <> "
    _ => " <unknown op> "
  end
end

# --- FunctionArgs ---

function dumpFunctionArgs(args::FunctionArgs)::String
  @match args begin
    FUNCTIONARGS(__) => begin
      local pos = join((dumpExp(a) for a in args.args), ", ")
      local named = join((dumpNamedArg(na) for na in args.argNames), ", ")
      if !isempty(pos) && !isempty(named)
        pos * ", " * named
      elseif !isempty(pos)
        pos
      else
        named
      end
    end
    FOR_ITER_FARG(__) => begin
      local e = dumpExp(args.exp)
      local iters = join((dumpForIterator(i) for i in args.iterators), ", ")
      local thread = isa(args.iterType, THREAD) ? "threaded " : ""
      e * " " * thread * "for " * iters
    end
    _ => "<unknown args>"
  end
end

function dumpNamedArg(na::NamedArg)::String
  @match na begin
    NAMEDARG(__) => na.argName * " = " * dumpExp(na.argValue)
    _ => "<unknown named arg>"
  end
end

function dumpForIterator(it)::String
  @match it begin
    ITERATOR(__) => begin
      local s = it.name
      if !isnothing(it.guardExp)
        s = s * " guard " * dumpExp(it.guardExp.data)
      end
      if !isnothing(it.range)
        s = s * " in " * dumpExp(it.range.data)
      end
      s
    end
    _ => "<unknown iterator>"
  end
end

# --- TypeSpec ---

function dumpTypeSpec(ts::TypeSpec)::String
  @match ts begin
    TPATH(__) => begin
      local s = dumpPath(ts.path)
      if !isnothing(ts.arrayDim)
        s = s * dumpSubscripts(collect(ts.arrayDim.data))
      end
      s
    end
    TCOMPLEX(__) => begin
      local p = dumpPath(ts.path)
      local tys = join((dumpTypeSpec(t) for t in ts.typeSpecs), ", ")
      local s = p * "<" * tys * ">"
      if !isnothing(ts.arrayDim)
        s = s * dumpSubscripts(collect(ts.arrayDim.data))
      end
      s
    end
    _ => "<unknown typespec>"
  end
end

# --- Direction ---

function dumpDirection(dir::Direction)::String
  @match dir begin
    BIDIR(__) => ""
    INPUT(__) => "input "
    OUTPUT(__) => "output "
    _ => ""
  end
end
