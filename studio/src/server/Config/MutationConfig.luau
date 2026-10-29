--!strict
-- Catálogo reservado para o futuro. Registrar um ID não ativa efeitos ou sorteios.
local mutations: { [string]: { Name: string } } = {
	Shine = table.freeze({ Name = "Shine" }),
	Double = table.freeze({ Name = "Double" }),
}
return table.freeze({ Mutations = table.freeze(mutations) })
