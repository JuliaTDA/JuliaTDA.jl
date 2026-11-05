using MapperStudio
Base.exit_on_sigint(false)
port = parse(Int, get(ENV, "MAPPER_STUDIO_PORT", "8090"))
MapperStudio.serve(; port)
