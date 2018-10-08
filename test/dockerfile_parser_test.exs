defmodule ExDockerBuild.DockerfileParserTest do
  use ExUnit.Case, async: true

  alias ExDockerBuild.DockerfileParser, as: Parser

  setup do
    base_dir = Path.join([System.cwd!(), "test", "fixtures"])
    {:ok, base_dir: base_dir}
  end

  def parse(base_dir, file) do
    Path.join([base_dir, file])
    |> Parser.parse!()
  end

  test "parses correctly a simple Dockerfile", %{base_dir: base_dir} do
    result = parse(base_dir, "Dockerfile_simple.dockerfile")

    assert result == [
             {"FROM", "elixir:latest"},
             {"WORKDIR", "/opt/app"},
             {"ENV", "MIX_ENV prod"},
             {"RUN", "mix local.hex --force"},
             {"RUN", "mix local.rebar --force"},
             {"COPY", ". ."},
             {"RUN", "mix deps.get --only prod"},
             {"RUN", "mix release"},
             {"ENTRYPOINT", "[\"_build/prod/rel/clock/bin/clock\"]"},
             {"CMD", "[\"foreground\"]"}
           ]
  end

  test "parses correctly a bind mount Dockerfile", %{base_dir: base_dir} do
    result = parse(base_dir, "Dockerfile_bind.dockerfile")

    assert result == [
             {"FROM", "elixir:1.7.3"},
             {"VOLUME", "/Users/kiro/test:/data"},
             {"RUN", "echo \"hello-world!!!!\" > /data/myfile.txt"},
             {"CMD", "[\"cat\", \"/data/myfile.txt\"]"}
           ]
  end

  test "parses correctly a the erlang Dockerfile", %{base_dir: base_dir} do
    result = parse(base_dir, "Dockerfile_erlang.dockerfile")

    assert result == [
             {"FROM", "buildpack-deps:stretch"},
             {"ENV", "OTP_VERSION=\"21.0.9\""},
             {"RUN",
              "set -xe  && OTP_DOWNLOAD_URL=\"https://github.com/erlang/otp/archive/OTP-${OTP_VERSION}.tar.gz\"  && OTP_DOWNLOAD_SHA256=\"fbbd21358ddcf657b3125db636ef2260d421f5024ff9b4ad03c5e690651ec0dd\"  && runtimeDeps='libodbc1  libsctp1  libwxgtk3.0'  && buildDeps='unixodbc-dev  libsctp-dev  libwxgtk3.0-dev'  && apt-get update  && apt-get install -y --no-install-recommends $runtimeDeps  && apt-get install -y --no-install-recommends $buildDeps  && curl -fSL -o otp-src.tar.gz \"$OTP_DOWNLOAD_URL\"  && echo \"$OTP_DOWNLOAD_SHA256  otp-src.tar.gz\" | sha256sum -c -  && export ERL_TOP=\"/usr/src/otp_src_${OTP_VERSION%%@*}\"  && mkdir -vp $ERL_TOP  && tar -xzf otp-src.tar.gz -C $ERL_TOP --strip-components=1  && rm otp-src.tar.gz  && ( cd $ERL_TOP  && ./otp_build autoconf  && gnuArch=\"$(dpkg-architecture --query DEB_BUILD_GNU_TYPE)\"  && ./configure --build=\"$gnuArch\"  && make -j$(nproc)  && make install )  && find /usr/local -name examples | xargs rm -rf  && apt-get purge -y --auto-remove $buildDeps  && rm -rf $ERL_TOP /var/lib/apt/lists/*"},
             {"CMD", "[\"erl\"]"},
             {"ENV", "REBAR_VERSION=\"2.6.4\""},
             {"RUN",
              "set -xe  && REBAR_DOWNLOAD_URL=\"https://github.com/rebar/rebar/archive/${REBAR_VERSION}.tar.gz\"  && REBAR_DOWNLOAD_SHA256=\"577246bafa2eb2b2c3f1d0c157408650446884555bf87901508ce71d5cc0bd07\"  && mkdir -p /usr/src/rebar-src  && curl -fSL -o rebar-src.tar.gz \"$REBAR_DOWNLOAD_URL\"  && echo \"$REBAR_DOWNLOAD_SHA256 rebar-src.tar.gz\" | sha256sum -c -  && tar -xzf rebar-src.tar.gz -C /usr/src/rebar-src --strip-components=1  && rm rebar-src.tar.gz  && cd /usr/src/rebar-src  && ./bootstrap  && install -v ./rebar /usr/local/bin/  && rm -rf /usr/src/rebar-src"},
             {"ENV", "REBAR3_VERSION=\"3.6.1\""},
             {"RUN",
              "set -xe  && REBAR3_DOWNLOAD_URL=\"https://github.com/erlang/rebar3/archive/${REBAR3_VERSION}.tar.gz\"  && REBAR3_DOWNLOAD_SHA256=\"40b3c85440f3235c7b149578d0211bdf57d1c66390f888bb771704f8abc71033\"  && mkdir -p /usr/src/rebar3-src  && curl -fSL -o rebar3-src.tar.gz \"$REBAR3_DOWNLOAD_URL\"  && echo \"$REBAR3_DOWNLOAD_SHA256 rebar3-src.tar.gz\" | sha256sum -c -  && tar -xzf rebar3-src.tar.gz -C /usr/src/rebar3-src --strip-components=1  && rm rebar3-src.tar.gz  && cd /usr/src/rebar3-src  && HOME=$PWD ./bootstrap  && install -v ./rebar3 /usr/local/bin/  && rm -rf /usr/src/rebar3-src"}
           ]
  end

  test "parses file content instead of a file" do
    content = """
    FROM elixir:1.7.3
    VOLUME /Users/kiro/test:/data
    RUN echo "hello-world!!!!" > /data/myfile.txt
    CMD ["cat", "/data/myfile.txt"]
    """

    result = Parser.parse!(content)

    assert result == [
             {"FROM", "elixir:1.7.3"},
             {"VOLUME", "/Users/kiro/test:/data"},
             {"RUN", "echo \"hello-world!!!!\" > /data/myfile.txt"},
             {"CMD", "[\"cat\", \"/data/myfile.txt\"]"}
           ]
  end
end
