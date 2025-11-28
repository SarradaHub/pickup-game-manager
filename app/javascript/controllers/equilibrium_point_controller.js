import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = [
    "incomeCheckbox",
    "expenseCheckbox",
    "incomeContainer",
    "expenseContainer",
    "selectedIncomeTypes",
    "selectedExpenseTypes",
    "selectedOptions",
    "resultContainer"
  ]

  connect() {
    // Update selected options display on initial load
    this.updateSelectedOptions()
    
    // Calculate on initial load if there are any checked boxes
    const incomeTypes = this.getSelectedIncomeTypes()
    const expenseTypes = this.getSelectedExpenseTypes()
    
    if (incomeTypes.length > 0 || expenseTypes.length > 0) {
      this.calculate()
    }
  }

  calculate() {
    this.updateSelectedOptions()
    
    const incomeTypes = this.getSelectedIncomeTypes()
    const expenseTypes = this.getSelectedExpenseTypes()

    // If no selections, show no selection message
    if (incomeTypes.length === 0 && expenseTypes.length === 0) {
      this.showNoSelection()
      return
    }

    // Show loading state
    this.showLoading()

    // Make AJAX call to calculate endpoint
    fetch('/dashboard/calculate_equilibrium', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content')
      },
      body: JSON.stringify({
        income_types: incomeTypes,
        expenses_types: expenseTypes
      })
    })
    .then(response => {
      if (!response.ok) {
        throw new Error('Network response was not ok')
      }
      return response.json()
    })
    .then(data => {
      this.updateResult(data)
      this.hideLoading()
    })
    .catch(error => {
      console.error('Error calculating equilibrium point:', error)
      this.showError('Erro ao calcular o ponto de equilíbrio. Por favor, tente novamente.')
      this.hideLoading()
    })
  }

  getSelectedIncomeTypes() {
    return this.incomeCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)
  }

  getSelectedExpenseTypes() {
    return this.expenseCheckboxTargets
      .filter(checkbox => checkbox.checked)
      .map(checkbox => checkbox.value)
  }

  updateSelectedOptions() {
    const incomeTypes = this.getSelectedIncomeTypes()
    const expenseTypes = this.getSelectedExpenseTypes()

    // Update selected income types display
    if (this.hasSelectedIncomeTypesTarget) {
      if (incomeTypes.length > 0) {
        this.selectedIncomeTypesTarget.innerHTML = incomeTypes
          .map(type => `<span class="inline-block bg-success-100 text-success-700 px-2 py-1 rounded text-xs mr-1 mb-1">${type}</span>`)
          .join('')
      } else {
        this.selectedIncomeTypesTarget.innerHTML = '<span class="text-neutral-500">Nenhuma selecionada</span>'
      }
    }

    // Update selected expense types display
    if (this.hasSelectedExpenseTypesTarget) {
      if (expenseTypes.length > 0) {
        this.selectedExpenseTypesTarget.innerHTML = expenseTypes
          .map(type => `<span class="inline-block bg-error-100 text-error-700 px-2 py-1 rounded text-xs mr-1 mb-1">${type}</span>`)
          .join('')
      } else {
        this.selectedExpenseTypesTarget.innerHTML = '<span class="text-neutral-500">Nenhuma selecionada</span>'
      }
    }
  }

  updateResult(data) {
    // Find the result container (it's in a separate partial)
    const resultContainer = document.getElementById('equilibrium-point-result')
    if (!resultContainer) {
      console.warn('Equilibrium point result container not found')
      return
    }

    // Build the result HTML
    let html = this.buildResultHTML(data)
    
    // Update the container
    resultContainer.innerHTML = html
  }

  buildResultHTML(data) {
    if (!data || data.equilibrium_point === undefined) {
      return this.buildNoSelectionHTML()
    }

    const equilibriumPoint = data.equilibrium_point
    const incomeTotal = data.income_total || 0
    const expensesTotal = data.expenses_total || 0
    const incomeUnitValues = data.income_unit_values || {}
    const expensesUnitValues = data.expenses_unit_values || {}
    const expensesByType = data.expenses_by_type || {}

    let html = `
      <div class="rounded-lg bg-white border border-neutral-200 p-6 shadow-sm hover:shadow-md transition-shadow">
        <div class="flex gap-4 mb-4">
          <div class="flex items-center" aria-hidden="true">⚖️</div>
          <div class="flex-1">
            <h3 class="text-lg font-semibold text-neutral-900 mb-2 flex items-center gap-2">
              <span class="w-1 h-5 bg-primary-500 rounded-full"></span>
              Resultado do Equilíbrio Financeiro
            </h3>
            <p class="text-sm text-neutral-600">
              Esta análise mostra o ponto de equilíbrio entre suas receitas e despesas selecionadas.
            </p>
          </div>
        </div>
        
        <div class="space-y-6">
          <!-- Main Result -->
          <div class="rounded-lg bg-gradient-to-br from-primary-50 to-primary-100 border-2 border-primary-300 p-4 shadow-sm">
            <p class="text-base font-semibold text-neutral-900 mb-1">
              <strong class="text-primary-700">Ponto de Equilíbrio:</strong> 
              <span class="text-primary-600">${equilibriumPoint}</span>
            </p>
            <p class="text-sm text-neutral-600">
              Este valor representa o número de unidades de receita necessárias para cobrir as despesas selecionadas.
            </p>
          </div>

          <!-- Financial Summary -->
          <div>
            <h4 class="text-base font-semibold text-neutral-900 mb-4">Resumo Financeiro</h4>
            <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
              <div class="rounded-lg bg-white border-l-4 border-l-success-500 border-r border-t border-b border-neutral-200 p-4 bg-gradient-to-r from-success-50/30 to-white shadow-sm">
                <div class="flex items-center gap-3">
                  <div class="flex items-center" aria-hidden="true">💰</div>
                  <div class="flex-1">
                    <h5 class="text-sm font-medium text-neutral-500 mb-1">Receita Total</h5>
                    <p class="text-lg font-bold text-success-700">R$${this.formatCurrency(incomeTotal)}</p>
                    <p class="text-xs text-neutral-500 mt-1">${data.income_count || 0} tipo(s) selecionado(s)</p>
                  </div>
                </div>
              </div>

              <div class="rounded-lg bg-white border-l-4 border-l-error-500 border-r border-t border-b border-neutral-200 p-4 bg-gradient-to-r from-error-50/30 to-white shadow-sm">
                <div class="flex items-center gap-3">
                  <div class="flex items-center" aria-hidden="true">💸</div>
                  <div class="flex-1">
                    <h5 class="text-sm font-medium text-neutral-500 mb-1">Despesas Total</h5>
                    <p class="text-lg font-bold text-error-700">R$${this.formatCurrency(expensesTotal)}</p>
                    <p class="text-xs text-neutral-500 mt-1">${data.expenses_count || 0} tipo(s) selecionado(s)</p>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <!-- Detailed Breakdown -->
          <div>
            <h4 class="text-base font-semibold text-neutral-900 mb-4">Detalhamento por Tipo</h4>
    `

    // Income Details
    if (Object.keys(incomeUnitValues).length > 0) {
      html += `
            <div class="mb-6">
              <h5 class="text-sm font-semibold text-neutral-700 mb-3">Receitas Selecionadas</h5>
              <div class="space-y-2">
      `
      for (const [type, data] of Object.entries(incomeUnitValues)) {
        html += `
                <div class="rounded-lg bg-gradient-to-r from-success-50/50 to-white border-l-4 border-l-success-400 border-r border-t border-b border-neutral-200 p-3 shadow-sm">
                  <div class="flex justify-between items-start mb-2">
                    <span class="text-sm font-medium text-neutral-900">${type}</span>
                    <span class="text-xs text-neutral-500">(${data.count} registro(s))</span>
                  </div>
                  <div class="flex flex-wrap gap-4 text-xs text-neutral-600">
                    <span>Valor unitário médio: <span class="font-semibold text-success-700">R$${this.formatCurrency(data.unit_value)}</span></span>
                    <span>Total: <span class="font-semibold text-success-700">R$${this.formatCurrency(data.total_value)}</span></span>
                  </div>
                </div>
        `
      }
      html += `
              </div>
            </div>
      `
    }

    // Expense Details - Grouped by Type
    if (Object.keys(expensesByType).length > 0) {
      html += `
            <div class="mb-6">
              <h5 class="text-sm font-semibold text-neutral-700 mb-3">Despesas Selecionadas</h5>
              <div class="space-y-4">
      `
      for (const [type, expenses] of Object.entries(expensesByType)) {
        const typeSummary = expensesUnitValues[type] || {}
        html += `
                <div class="rounded-lg bg-gradient-to-r from-error-50/50 to-white border-l-4 border-l-error-400 border-r border-t border-b border-neutral-200 p-4 shadow-sm">
                  <div class="flex justify-between items-start mb-3">
                    <span class="text-base font-semibold text-neutral-900">${type}</span>
                    <span class="text-xs text-neutral-500">${expenses.length} registro(s)</span>
                  </div>
                  ${typeSummary.total_value ? `
                  <div class="flex flex-wrap gap-4 text-xs text-neutral-600 mb-3 pb-3 border-b border-neutral-200">
                    <span>Valor unitário médio: <span class="font-semibold text-error-700">R$${this.formatCurrency(typeSummary.unit_value)}</span></span>
                    <span>Total do tipo: <span class="font-semibold text-error-700">R$${this.formatCurrency(typeSummary.total_value)}</span></span>
                  </div>
                  ` : ''}
                  <div class="space-y-2">
                    <div class="text-xs font-semibold text-neutral-700 mb-2">Detalhamento:</div>
        `
        expenses.forEach(expense => {
          html += `
                    <div class="rounded bg-white border border-neutral-200 p-3 text-xs">
                      <div class="flex justify-between items-start mb-2">
                        <span class="font-medium text-neutral-900">${this.escapeHtml(expense.description)}</span>
                        <span class="text-neutral-500">${this.formatDate(expense.date)}</span>
                      </div>
                      <div class="grid grid-cols-3 gap-3 text-neutral-600">
                        <div>
                          <span class="text-neutral-500">Valor Unitário:</span>
                          <span class="font-semibold text-error-700 ml-1">R$${this.formatCurrency(expense.unit_value)}</span>
                        </div>
                        <div>
                          <span class="text-neutral-500">Quantidade:</span>
                          <span class="font-semibold text-error-700 ml-1">${expense.quantity}</span>
                        </div>
                        <div>
                          <span class="text-neutral-500">Total:</span>
                          <span class="font-semibold text-error-700 ml-1">R$${this.formatCurrency(expense.total_value)}</span>
                        </div>
                      </div>
                    </div>
          `
        })
        html += `
                  </div>
                </div>
        `
      }
      html += `
              </div>
            </div>
      `
    }

    // Cost Analysis
    const totalCost = equilibriumPoint * incomeTotal
    html += `
          <!-- Cost Analysis -->
          <div class="rounded-lg bg-info-50 border border-info-200 p-4">
            <h4 class="text-base font-semibold text-neutral-900 mb-2">Análise de Custo</h4>
            <p class="text-sm font-medium text-neutral-700 mb-1">Custo total para atingir o equilíbrio:</p>
            <p class="text-xl font-bold text-info-600 mb-1">R$${this.formatCurrency(totalCost)}</p>
            <p class="text-xs text-neutral-600">
              (${equilibriumPoint} unidades × R$${this.formatCurrency(incomeTotal)} de receita total)
            </p>
          </div>
        </div>
      </div>
    `

    return html
  }

  buildNoSelectionHTML() {
    return `
      <div class="rounded-lg bg-white border border-neutral-200 p-6 shadow-sm">
        <div class="text-center py-8">
          <p class="text-base font-semibold text-neutral-900 mb-2">Nenhuma seleção realizada</p>
          <p class="text-sm text-neutral-600">
            Selecione pelo menos um tipo de receita e um tipo de despesa para calcular o ponto de equilíbrio.
          </p>
        </div>
      </div>
    `
  }

  formatCurrency(value) {
    return parseFloat(value || 0).toFixed(2)
  }

  formatDate(dateString) {
    if (!dateString) return ''
    const date = new Date(dateString)
    return date.toLocaleDateString('pt-BR', { day: '2-digit', month: '2-digit', year: 'numeric' })
  }

  escapeHtml(text) {
    const div = document.createElement('div')
    div.textContent = text
    return div.innerHTML
  }

  showLoading() {
    const resultContainer = document.getElementById('equilibrium-point-result')
    if (resultContainer) {
      resultContainer.innerHTML = `
        <div class="rounded-lg bg-white border border-neutral-200 p-6 shadow-sm">
          <div class="text-center py-8">
            <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600 mb-4"></div>
            <p class="text-sm text-neutral-600">Calculando ponto de equilíbrio...</p>
          </div>
        </div>
      `
    }
  }

  hideLoading() {
    // Loading is replaced by result, so nothing to do here
  }

  showError(message) {
    const resultContainer = document.getElementById('equilibrium-point-result')
    if (resultContainer) {
      resultContainer.innerHTML = `
        <div class="rounded-lg bg-white border border-error-200 p-6 shadow-sm">
          <div class="text-center py-8">
            <p class="text-base font-semibold text-error-700 mb-2">Erro</p>
            <p class="text-sm text-neutral-600">${message}</p>
          </div>
        </div>
      `
    }
  }

  showNoSelection() {
    const resultContainer = document.getElementById('equilibrium-point-result')
    if (resultContainer) {
      resultContainer.innerHTML = this.buildNoSelectionHTML()
    }
  }
}

