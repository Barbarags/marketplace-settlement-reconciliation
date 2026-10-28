// Sanitized excerpt - identifiers, hosts, GUIDs and company-specific names removed.
// Original: Power Query M (Microsoft Fabric / Power BI Dataflow).

shared fn_GetParam = (nomeParametro as text) =>
let
    Valor = Record.Field(
        Record.FromList(
            Table.SelectRows(
                CONFIG_CONCILIACAO,
                each [parametro] = nomeParametro
            )[valor],
            {"valor"}
        ),
        "valor"
    )
in
    Valor;
