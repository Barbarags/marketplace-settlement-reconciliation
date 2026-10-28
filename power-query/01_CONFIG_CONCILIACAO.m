// Sanitized excerpt - identifiers, hosts, GUIDs and company-specific names removed.
// Original: Power Query M (Microsoft Fabric / Power BI Dataflow).

shared CONFIG_CONCILIACAO = let
    Fonte = #table(
        // Nomes das colunas
        {"parametro", "valor", "descricao"},
        // Linhas de configuração
        {
            {"MARGEM_TOLERANCIA",    1,    "Tolerância em R$ para considerar repasse conciliado"},
            {"MARGEM_COMPONENTE",    1,    "Tolerância por componente (comissão, frete, promo, taxa)"},
            {"VERSAO_REGRA",         1,    "Versão atual das regras de conciliação"},
            {"DT_VIGENCIA",          null, "Data de início da vigência das regras atuais"}
        }
    ),
    TipagemColunas = Table.TransformColumnTypes(Fonte, {
        {"parametro", type text},
        {"valor",     type number},
        {"descricao", type text}
    })
in
    TipagemColunas;
