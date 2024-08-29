%{
  configs: [
    %{
      name: "default",
      plugins: [],
      requires: [],
      strict: false,
      parse_timeout: 5000,
      color: true,
      checks: %{
        disabled: [
          # this means that `TabsOrSpaces` will not run
          {Credo.Check.Design.TagTODO, []}
        ]
      }
    }
  ]
}
