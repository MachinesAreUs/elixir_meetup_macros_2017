class: center, middle, cover-slide
# Metaprogramación en Elixir

Agustín Ramos

@MachinesAreUs

Julio 2017

.bounce[![Elixir Logo](./img/elixir.png)]

---
class: middle
# Disclaimer

---
class: middle
# ¡Elixir no es mi lenguaje favorito!

![scream](./img/scream.jpg)

---
class: center, middle

# Pero es bastante interesante,
# muy productivo y la plataforma es increíble.

---
class: middle
# Un poco de historia

---
class: center, middle

![John McCarthy](./img/mccarthy2.png)

## ¿Quién es este señor?

---
class: center, middle
### "**John McCarthy** in his earth-shattering essay **Recursive Functions of Symbolic Expressions and Their Computation by Machine, Part I (1960)** defined the **whole language** in terms of **only seven functions and two special forms**: atom, car, cdr, cond, cons, eq, quote, lambda, and label. **Through the composition of those nine forms**, McCarthy was able to **describe the whole of computation** in a way that takes your breath away"

http://www-formal.stanford.edu/jmc/recursive/recursive.html

---
class: center, middle
## Estamos hablando de Lisp, 1960

---
class: center, middle

![Guy Steele](./img/steele.jpg)

## ¿Y éste?

---
class: center, middle
# Growing a Language
### Guy Steele, OOPSLA 1998

https://www.youtube.com/watch?v=_ahvzDzKdB0

---
class: center, middle
### “**A language design** can no longer be a thing. It **must be a pattern—a pattern for growth**—a pattern for growing the pattern for defining the patterns that programmers can use for their real work and their main goal.”

### “So I think the sole way to win is to plan for growth with help from users... **Parts of the language must be designed to help the task of growth**.“

---
class: middle
# ¿Qué tiene que ver todo esto con Elixir?

---
class: middle
## .center[¿Cuáles son las palabras reservadas de Elixir?]

- def ?
- defmodule ?
- import ?
- do, end ?
- ...


---
class: center, middle

## Todas estas son macros

! && || .. in <> @ alias! and or binding defmodule def defp defprotocol defimpl defmacro defmacrop defstruct defoverridable defdelegate defexception destructure get_and_update_in if is_nil match? put_in raise reraise sigil_C sigil_D sigil_N sigil_R sigil_S sigil_T sigil_W sigil_c sigil_r sigil_s sigil_w to_char_list to_charlist to_string unless update_in use var! |>

https://github.com/elixir-lang/elixir/blob/master/lib/elixir/lib/kernel.ex#L2758

---
class: center, middle
# ¿Por qué?

---
class: middle
# Macros building blocks:
# quote & unquote

---
class: center, middle
# En Elixir, un programa puede representarse con las mismas estructuras de datos de elixir

---
class: center, middle
![Scream](./img/scream_emoji.png)

---
# quote

--
**`quote`** recibe un bloque y convierte el código dentro del mismo a su representación en forma de AST.

--
```elixir
iex> quote do: 2 + 3

{:+, [context: Elixir, import: Kernel], [1, 2]}
```

--
```elixir
iex> quote do: 2 + 3 * 5

iex(35)> quote do: 2 + 3 * 5
{:+, [context: Elixir, import: Kernel],
 [2, {:*, [context: Elixir, import: Kernel], [3, 5]}]}
```

--
```elixir
iex> String.reverse("hola")

{{:., [], [{:__aliases__, [alias: false], [:String]}, :reverse]}, [], ["hola"]}
```

---
# unquote

--
**`unquote`** solo puede utilizarse dentro de un bloque `quote`, y sirve para insertar un fragmento de AST dentro del bloque que se está **`quoteando`** (bad spanglish).

--

**Ejemplo**: vamos a construir el AST de un programa a partir de 2 AST's más simples:

--

AST 1:

```elixir
iex> range_ast = quote do: 1..3

{:.., [context: Elixir, import: Kernel], [1, 3]}
```
--

AST 2:

```elixir
iex> func_ast = quote do: fn(x) -> x*2 end

{:fn, [],
 [{:->, [],
   [[{:x, [], Elixir}],
    {:*, [context: Elixir, import: Kernel], [{:x, [], Elixir}, 2]}]}]}
```

---
# unquote

AST Compuesto:

```elixir
iex> prog_ast = quote do
...>   Enum.map unquote(range_ast), unquote(func_ast)
...> end


{{:., [], [{:__aliases__, [alias: false], [:Enum]}, :map]}, [],
 [{:.., [context: Elixir, import: Kernel], [1, 3]},
  {:fn, [],
   [{:->, [],
     [[{:x, [], Elixir}],s
      {:*, [context: Elixir, import: Kernel], [{:x, [], Elixir}, 2]}]}]}]}
```
--

Y en forma de texto:

```elixir
iex> Macro.to_string(prog_ast)

"Enum.map(1..3, fn x -> x * 2 end)"
```

---
# AST expansion
--

```elixir
iex> ast = quote do
...>   unless 1 > 2 do
...>     :ok
...>   end
...> end

{:unless, [context: Elixir, import: Kernel],
 [{:>, [context: Elixir, import: Kernel], [1, 2]}, [do: :ok]]}
```
--

```elixir
iex> ast2 = Macro.expand_once ast, __ENV__

{:if, [context: Kernel, import: Kernel],
 [{:>, [context: Elixir, import: Kernel], [1, 2]}, [do: nil, else: :ok]]}
```
--

```elixir
iex> IO.puts Macro.to_string(ast2)

if(1 > 2) do
  nil
else
  :ok
end
:ok
```

---
# AST expansion
--

```elixir
iex> ast3 = Macro.expand_once ast2, __ENV__

{:case, [optimize_boolean: true],
 [{:>, [context: Elixir, import: Kernel], [1, 2]},
  [do: [{:->, [],
     [[{:when, [],
        [{:x, [counter: 1], Kernel},
         {:in, [context: Kernel, import: Kernel],
          [{:x, [counter: 1], Kernel}, [false, nil]]}]}], :ok]},
    {:->, [], [[{:_, [], Kernel}], nil]}]]]}
```
--

```elixir
iex> IO.puts Macro.to_string(ast3)

case(1 > 2) do
  x when x in [false, nil] ->
    :ok
  _ ->
    nil
end
:ok
```

---
# Creación de una macro

--

**1.** Se define con la macro **`defmacro`**. Sus partes son:

  + **nombre**
  + **parámetros** que recibe
  + bloque de **código**

--

```elixir
defmacro my_macro(param1, param2...) do
  # code here...
end
```
--
**2.** Todas las macros deben definirse **dentro de un módulo**.

---
# Creación de una macro

**3.** Se espera que el cuerpo de una macro **devuelva un fragmento de AST**.

--

```elixir
defmodule MyModule do
  defmacro my_macro(param1, param2...) do
    # Maybe some code here
    quote do
      # quoted code (AST fragment) here
    end
  end
end
```
--
**4.** **Importante**: los parámetros que recibe el cuerpo de la macro vienen en forma de AST (quoted).

---
# Uso de una macro

--
**1.** Para usar una macro, es necesario que el módulo donde está definida esté disponible

--

```elixir
require MyModule
```
--

**2.** Al invocar una macro, el punto de la llamada se sustituye por el fragmento de AST generado dentro del cuerpo de la macro. Por ejemplo:
--

```elixir
require MyModule
MyModule.sum 1, 2  ===> {:+, [context: Elixir, import: Kernel], [1, 2]}
```
--

**3**. Las macros se procesan en **tiempo de compilación** mediante un proceso llamado **expansión de macros**.

--

**4**. El proceso de se repite hasta que ya no hay más macros por expandir.

---
class: center
background-image: url(./img/macro-expansion-1.png)

# Proceso de compilación de Elixir


---
# Ejemplo 1

Nuestra macro va a crear un método dentro del módulo desde donde es llamada la macro. El módulo cliente especifica el nombre y el cuerpo de la función.
--

```elixir
defmodule MyMacros do
  defmacro new_function(name, do: block) do
    quote do
      def unquote(name)() do
        unquote(block)
      end
    end
  end
end
```
--

```elixir
defmodule MyModule do
  require MyMacros
  MyMacros.new_function :hello, do: "world"
  MyMacros.new_function :foo,   do: "bar"
end
```
--

```elixir
iex(5)> MyModule.hello
"world"
iex(6)> MyModule.foo
"bar"
```

---
# Y eso... ¿para qué sirve?

--
+ Para extender el lenguaje

--
+ i.e. Para crear DSL's


---
class: middle
# Importancia de las macros en Elixir

---
# stdlib

En la stdlib, el uso de macros es [interesante](https://docs.google.com/spreadsheets/d/11IZJIZyr2173wsOu7fu6DJoQ6YBH7f5C_nBn4mpYTZE/edit?usp=sharing)

---
# Ecto

--

+ Ecto es el framework oficial  para acceder a bases de datos.
--

+ Provee DSL's para:
  - Modelado de datos
  - Migraciones de datos
  - Queries

---
# Ecto

**Ejemplo 1**: Definición de un esquema.

```elixir
defmodule MyApp.Comment do
  use Ecto.Model
  import Ecto.Query

  schema "comments" do
    field :commenter, :string
    field :title, :string
    field :votes, :integer

    belongs_to :post, MyApp.Post
  end
end
```

--
.center[https://github.com/elixir-ecto/ecto/blob/master/lib/ecto/schema.ex#L346]

---
# Ecto

**Ejemplo 2**: queries.

```elixir
iex> query = from c in MyApp.Comment,
iex>   join: p in assoc(c, :post),
iex>  where: p.id == 1,
iex> select: c
iex> App.Repo.all query
```

--
.center[https://github.com/elixir-ecto/ecto/blob/master/lib/ecto/query.ex#L517]

---
class: middle
# Y para tus propios DSLs...

---
# Ejemplo: DSL de transiciones en una máquina de estados

--

```elixir
defmodule StateMachine do
  machine = [
    running: {:pause,  :paused},
    running: {:stop,   :stopped},
    paused:  {:resume, :running}
  ]

  for {state, {action, new_state}} <- machine do
    def unquote(action)(unquote(state)) do
      unquote(new_state)
    end
  end

  def initial, do: :running
end
```
---
# Ejemplo: DSL de transiciones en una máquina de estados

```elixir
iex> import StateMachine
iex> initial
:running
iex> initial |> pause
:paused
iex> initial |> pause |> resume |> stop
:stopped
```

---
# Ejemplo: Cliente del API de Github

--

```elixir
defmodule Github do
  HTTPotion.start
  @username "MachinesAreUs"
  "https://api.github.com/users/#{@username}/repos"
    |> HTTPotion.get(headers: ["User-Agent": @username])
    |> Map.get(:body)
    |> Poison.decode!()
    |> Enum.each(fn repo ->
      def unquote(String.to_atom(repo["name"]))() do
        unquote(Macro.escape(repo))
      end
    end)

  def go(repo) do
    url = apply(__MODULE__, repo, [])["html_url"]
    IO.puts "Launching browser to #{url}..."
    System.cmd("open", [url])
  end
end
```

---
# Ejemplo: Cliente del API de Github

```elixir
iex> Github.
Albacore/0                          CodeCamp2016/0
Hystrix/0                           RubySwing/0
VizMyType/0                         advent_of_code/0
codeeval/0                          elixir_meetup_macros/0
...
```
--

```elixir
iex> repo = Github.elixir_meetup_macros
%{"archive_url" => "https:/api.github.com/repos/MachinesAreUs/...
...
```
--

```elixir
iex> Map.get repo, "html_url"
"https://github.com/MachinesAreUs/elixir_meetup_macros"
```
--

```elixir
iex> Github.go :elixir_meetup_macros
```

---
# Ejemplo de proyecto real

```elixir
news_extractor :EFE,
  headline:       [xpath: "NewsItem/NewsComponent/NewsLines/HeadLine"],
  copyright_line: [xpath: "NewsItem/NewsComponent/NewsLines/CopyrightLine"],
  creation_date:  [xpath: "NewsItem/Identification/NewsIdentifier/DateId", with: [to_date: "%Y-%m-%d %H:%M:%S%z"],
  body:           [xpath: "NewsItem/NewsComponent/ContentItem/DataContent/body/body.content"],
  provider:       [literal: "EFE"]
```
--

```elixir
iex> "saple_news.xml" |> File.read! |> EFE.extract
```
--

```elixir
%NewsItem{
  headline: "El gobierno de EU puede ver fotos de desnudos, segun Edward Snowden",
  body: "John Oliver, comediante de la cadena de television HBO, dio su mejor golpe hasta el momento: una entrevista a profundidad con Edward Snowden, excontratista de la Agencia Nacional de Seguridad (NSA, por sus siglas en ingles) de Estados Unidos.",
  creation_date: #Ecto.DateTime<2015-07-17T06:13:05Z>,
  provider: "EFE"
  copyright_line: "© EFE 2015. Está expresamente prohibida la redistribución y la redifusión de todo o parte de los contenidos de los servicios de Efe, sin previo y expreso consentimiento de la Agencia EFE S.A."}
```

---
class: center, middle, cover-slide

# ¡Happy Elixir coding!

Agustín Ramos

@MachinesAreUs

.bounce[![Elixir Logo](./img/elixir.png)]
