# Este arquivo deve garantir a existência de registros necessários para executar a aplicação em todos os ambientes (produção,
# desenvolvimento, teste). O código aqui deve ser idempotente para que possa ser executado a qualquer momento em qualquer ambiente.
# Os dados podem ser carregados com o comando bin/rails db:seed (ou criados junto com o banco de dados com db:setup).

puts "🌱 Populando banco de dados..."

# Calcular datas dinâmicas baseadas em hoje
today = Date.today
# Encontrar próximo sábado (6 = sábado no Date#wday do Ruby)
days_until_saturday = (6 - today.wday) % 7
days_until_saturday = 7 if days_until_saturday == 0 && today.wday != 6
first_match_date = today + days_until_saturday
match_dates = [
  first_match_date,
  first_match_date + 7.days,
  first_match_date + 14.days,
  first_match_date + 21.days
]

# Limpar dados existentes para garantir uma população limpa
puts "🧹 Limpando dados existentes..."
AthleteMatch.destroy_all
Payment.destroy_all
Athlete.destroy_all
Match.destroy_all
Income.destroy_all
Expense.destroy_all
TransactionCategory.destroy_all

puts "👥 Criando atletas..."
athletes = {
  joao_silva: {
    name: "João Silva",
    phone: 1234567890,
    date_of_birth: Date.parse("1990-05-15")
  },
  maria_santos: {
    name: "Maria Santos",
    phone: 9876543210,
    date_of_birth: Date.parse("1992-08-22")
  },
  pedro_oliveira: {
    name: "Pedro Oliveira",
    phone: 5551234567,
    date_of_birth: Date.parse("1988-12-10")
  },
  ana_costa: {
    name: "Ana Costa",
    phone: 7778889999,
    date_of_birth: Date.parse("1995-03-28")
  },
  carlos_rodrigues: {
    name: "Carlos Rodrigues",
    phone: 4445556666,
    date_of_birth: Date.parse("1993-07-14")
  },
  julia_ferreira: {
    name: "Júlia Ferreira",
    phone: 1112223333,
    date_of_birth: Date.parse("1991-11-05")
  }
}

athletes.each do |key, attributes|
  Athlete.find_or_create_by!(name: attributes[:name]) do |athlete|
    athlete.phone = attributes[:phone]
    athlete.date_of_birth = attributes[:date_of_birth]
  end
  puts "  ✅ Atleta criado: #{attributes[:name]}"
end

puts "🏟️ Criando partidas..."
matches = {
  primeira_semana: {
    date: first_match_date,
    location: "COPM"
  },
  segunda_semana: {
    date: first_match_date + 7.days,
    location: "COPM"
  },
  terceira_semana: {
    date: first_match_date + 14.days,
    location: "COPM"
  },
  quarta_semana: {
    date: first_match_date + 21.days,
    location: "COPM"
  }
}

matches.each do |key, attributes|
  Match.find_or_create_by!(date: attributes[:date], location: attributes[:location]) do |match|
    match.date = attributes[:date]
    match.location = attributes[:location]
  end
  puts "  ✅ Partida criada: #{attributes[:location]} em #{attributes[:date]}"
end

puts "🏷️ Criando categorias de transação..."
transaction_categories = {
  diario: {
    name: "Diário",
    description: "Receita de participação diária em jogos"
  },
  mensal: {
    name: "Mensal",
    description: "Receita de assinatura mensal"
  }
}

transaction_categories.each do |key, attributes|
  TransactionCategory.find_or_create_by!(name: attributes[:name]) do |category|
    category.description = attributes[:description]
  end
  puts "  ✅ Categoria de transação criada: #{attributes[:name]}"
end

puts "💰 Criando receitas..."
incomes = {
  diario: {
    transaction_category_name: "Diário",
    unit_value: 15.0,
    date: today
  },
  mensal: {
    transaction_category_name: "Mensal",
    unit_value: 35.0,
    date: today + 5.days
  }
}

incomes.each do |key, attributes|
  transaction_category = TransactionCategory.find_by!(name: attributes[:transaction_category_name])
  Income.find_or_create_by!(transaction_category: transaction_category, date: attributes[:date]) do |income|
    income.unit_value = attributes[:unit_value]
    income.date = attributes[:date]
  end
  puts "  ✅ Receita criada: #{attributes[:transaction_category_name]} - R$ #{attributes[:unit_value]}"
end

puts "💸 Criando despesas..."
expenses = {
  campo: {
    type: "Básico",
    description: "Campo",
    unit_value: 650.0,
    quantity: 1,
    date: today
  },
  goleiro: {
    type: "Intermediário",
    description: "Goleiro",
    unit_value: 50.0,
    quantity: 2,
    date: today + 1.day
  },
  camisa: {
    type: "Intermediário",
    description: "Camisa de Futebol",
    unit_value: 350.0,
    quantity: 1,
    date: today + 2.days
  },
  bolas: {
    type: "Intermediário",
    description: "Bolas de Futebol",
    unit_value: 150.0,
    quantity: 1,
    date: today + 3.days
  },
  churrasqueira: {
    type: "Avançado",
    description: "Churrasqueira",
    unit_value: 650.0,
    quantity: 1,
    date: today + 4.days
  }
}

expenses.each do |key, attributes|
  Expense.find_or_create_by!(type: attributes[:type], description: attributes[:description], date: attributes[:date]) do |expense|
    expense.unit_value = attributes[:unit_value]
    expense.quantity = attributes[:quantity]
    expense.date = attributes[:date]
  end
  puts "  ✅ Despesa criada: #{attributes[:type]} - #{attributes[:description]} - R$ #{attributes[:unit_value]} x #{attributes[:quantity]}"
end

puts "🤝 Criando partidas de atletas..."
athlete_matches_data = [
  { athlete_name: "João Silva", match_date: match_dates[0] },
  { athlete_name: "Maria Santos", match_date: match_dates[1] },
  { athlete_name: "Pedro Oliveira", match_date: match_dates[2] },
  { athlete_name: "Ana Costa", match_date: match_dates[3] },
  { athlete_name: "João Silva", match_date: match_dates[1] },
  { athlete_name: "Maria Santos", match_date: match_dates[2] },
  { athlete_name: "Pedro Oliveira", match_date: match_dates[3] },
  { athlete_name: "Ana Costa", match_date: match_dates[0] },
  { athlete_name: "Carlos Rodrigues", match_date: match_dates[0] },
  { athlete_name: "Júlia Ferreira", match_date: match_dates[1] },
  { athlete_name: "Carlos Rodrigues", match_date: match_dates[2] },
  { athlete_name: "Júlia Ferreira", match_date: match_dates[3] }
]

athlete_matches_data.each do |data|
  athlete = Athlete.find_by!(name: data[:athlete_name])
  match = Match.find_by!(location: "COPM", date: data[:match_date])

  AthleteMatch.find_or_create_by!(athlete: athlete, match: match)
  puts "  ✅ Partida de atleta criada: #{data[:athlete_name]} em COPM em #{data[:match_date]}"
end

puts "💳 Criando pagamentos..."
payments_data = [
  { athlete_name: "João Silva", match_date: match_dates[0], amount: 15.0, status: "paid", description: "Pagamento da primeira semana", transaction_category_name: "Diário" },
  { athlete_name: "Maria Santos", match_date: match_dates[1], amount: 15.0, status: "paid", description: "Pagamento da segunda semana", transaction_category_name: "Diário" },
  { athlete_name: "Pedro Oliveira", match_date: match_dates[2], amount: 15.0, status: "pending", description: "Pagamento da terceira semana", transaction_category_name: "Diário" },
  { athlete_name: "Ana Costa", match_date: match_dates[3], amount: 15.0, status: "paid", description: "Pagamento da quarta semana", transaction_category_name: "Diário" },
  { athlete_name: "Carlos Rodrigues", match_date: match_dates[0], amount: 15.0, status: "paid", description: "Pagamento da primeira semana", transaction_category_name: "Diário" },
  { athlete_name: "Júlia Ferreira", match_date: match_dates[1], amount: 15.0, status: "pending", description: "Pagamento da segunda semana", transaction_category_name: "Diário" }
]

payments_data.each do |data|
  athlete = Athlete.find_by!(name: data[:athlete_name])
  match = Match.find_by!(location: "COPM", date: data[:match_date])
  transaction_category = TransactionCategory.find_by!(name: data[:transaction_category_name])

  Payment.find_or_create_by!(athlete: athlete, match: match) do |payment|
    payment.amount = data[:amount]
    payment.status = data[:status]
    payment.description = data[:description]
    payment.date = match.date
    payment.transaction_category = transaction_category
  end
  status_pt = data[:status] == "paid" ? "pago" : "pendente"
  puts "  ✅ Pagamento criado: #{data[:athlete_name]} - R$ #{data[:amount]} (#{status_pt}) para COPM em #{data[:match_date]}"
end

puts ""
puts "🎉 População do banco de dados concluída com sucesso!"
puts ""
puts "📊 Resumo:"
puts "  🏷️ Categorias de Transação: #{TransactionCategory.count}"
puts "  👥 Atletas: #{Athlete.count}"
puts "  🏟️ Partidas: #{Match.count}"
puts "  💰 Receitas: #{Income.count}"
puts "  💸 Despesas: #{Expense.count}"
puts "  🤝 Partidas de Atletas: #{AthleteMatch.count}"
puts "  💳 Pagamentos: #{Payment.count}"
puts ""
puts "🚀 Agora você pode testar sua aplicação com dados realistas!"
puts "💡 Use 'bin/rails db:seed' para executar novamente a qualquer momento."
