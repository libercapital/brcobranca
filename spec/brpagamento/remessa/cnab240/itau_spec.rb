# -*- encoding: utf-8 -*-
#

require 'spec_helper'

RSpec.describe Brcobranca::Brpagamento::Remessa::Cnab240::Itau do
  let(:pagamento) do
    Brcobranca::Brpagamento::Remessa::Pagamento.new(
      cod_banco: '341',
      tipo_moeda: '09',
      tipo_movimento: '000',
      aviso_favorecido: '00',
      finalidade_ted: '00010',
      agencia: '12340',
      conta_corrente: '123456',
      digito_conta: '0',
      nome_favorecido: 'First Rate LTDA',
      documento_favorecido: '23666287000199',
      documento: 'IR252566',
      data_pagamento: '19/07/2018',
      valor: 20_000.00
    )
  end
  let(:params) do
    {
      documento_debitado: '91036701000136',
      empresa_mae: 'Abbye Ellingtun',
      agencia: '12340',
      conta_corrente: '123456',
      digito_conta: '0',
      logradouro: 'Av. Brasil',
      numero: '2340',
      complemento: '',
      cidade: 'Sao Paulo',
      cep: '13070178',
      uf_sacado: 'SP',
      finalidade_pagamento: '10',
      forma_pagamento: '41',
      tipo_pagamento: '98',
      pagamentos: [pagamento]
    }
  end
  let(:itau) { subject.class.new(params) }

  context 'formatacoes' do
    it 'codigo do banco deve ser 341' do
      expect(itau.cod_banco).to eq '341'
    end

    it 'nome do banco deve ser Banco do Ribeirão Preto com 30 posicoes' do
      nome_banco = itau.nome_banco
      expect(nome_banco.size).to eq 30
      expect(nome_banco[0..12]).to eq 'BANCO ITAU SA'
    end

    it 'versao do layout do arquivo deve ser 081' do
      expect(itau.versao_layout_arquivo).to eq '081'
    end

    it 'versao do layout do lote deve ser 040' do
      expect(itau.versao_layout_lote).to eq '040'
    end
  end

  context 'geracao remessa' do
    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }
      it { expect(itau.gera_arquivo).to eq(read_remessa('remessa-itau-cnab240.rem', itau.gera_arquivo, ['pagamento', 'remessa'])) }
    end
  end
end
