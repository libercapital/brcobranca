# -*- encoding: utf-8 -*-
#

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab240::BancoRibeiraoPreto do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(valor: 199.9,
                                       data_vencimento: Date.current,
                                       nosso_numero: 0,
                                       documento_sacado: '12345678901',
                                       numero_documento: '25555-4',
                                       codigo_multa: '3',
                                       nome_sacado: 'PABLO DIEGO JOSÉ FRANCISCO DE PAULA JUAN NEPOMUCENO MARÍA DE LOS REMEDIOS CIPRIANO DE LA SANTÍSSIMA TRINIDAD RUIZ Y PICASSO',
                                       endereco_sacado: 'RUA RIO GRANDE DO SUL São paulo Minas caçapa da silva junior',
                                       bairro_sacado: 'São josé dos quatro apostolos magros',
                                       cep_sacado: '12345678',
                                       cidade_sacado: 'Santa rita de cássia maria da silva',
                                       uf_sacado: 'SP',
                                       mensagem_200: 'BOLETO EMITIDO REF. NEGOCIAÇÂOO TERMO DE CESSÃO 25555 - PARCERIA ENTRE DAFITI E LIBER CAPITAL.')
  end
  let(:params) do
    { remessa_interna: true,
      empresa_mae: 'BANCO RIBEIRAO PRETO S/A',
      agencia: '5000',
      codigo_carteira: '1',
      conta_corrente: '19004615',
      documento_cedente: '00517645000105',
      convenio: '05000019004615',
      carteira: '112',
      pagamentos: [pagamento] }
  end
  let(:banco_ribeirao_preto) { subject.class.new(params) }

  context 'formatacoes' do
    it 'codigo do banco deve ser 001' do
      expect(banco_ribeirao_preto.cod_banco).to eq '741'
    end

    it 'nome do banco deve ser Banco do Ribeirão Preto com 30 posicoes' do
      nome_banco = banco_ribeirao_preto.nome_banco
      expect(nome_banco.size).to eq 30
      expect(nome_banco[0..19]).to eq 'BANCO RIBEIRAO PRETO'
    end

    it 'versao do layout do arquivo deve ser 083' do
      expect(banco_ribeirao_preto.versao_layout_arquivo).to eq '040'
    end

    it 'versao do layout do lote deve ser 040' do
      expect(banco_ribeirao_preto.versao_layout_lote).to eq '030'
    end

    it 'deve calcular o digito da agencia' do
      # digito calculado a partir do modulo 11 com base 9
      #
      # agencia = 1  2  3  4
      #
      #           4  3  2  1
      # x         9  8  7  6
      # =         36 24 14 6 = 80
      # 80 / 11 = 7 com resto 3
      expect(banco_ribeirao_preto.digito_agencia).to eq '0'
    end

    it 'deve calcular  digito da conta' do
      # digito calculado a partir do modulo 11 com base 9
      #
      # conta = 1  2  3  4  5
      #
      #         5  4  3  2  1
      # x       9  8  7  6  5
      # =       45 32 21 12 5 = 116
      # 116 / 11 = 10 com resto 5
      expect(banco_ribeirao_preto.digito_conta).to eq ' '
    end

    it 'cod. convenio deve retornar as informacoes corretas' do
      cod_convenio = banco_ribeirao_preto.codigo_convenio
      expect(cod_convenio).to eq '05000019004615      '
    end

    it 'info conta deve retornar as informacoes nas posicoes corretas' do

      expect(banco_ribeirao_preto.agencia).to eq '5000'
      expect(banco_ribeirao_preto.digito_agencia).to eq '0'
      expect(banco_ribeirao_preto.conta_corrente).to eq '19004615'
      expect(banco_ribeirao_preto.digito_conta).to eq ' '
    end
  end

  context 'geracao remessa' do
    context 'arquivo' do
      before { Timecop.freeze(Time.local(2015, 7, 14, 16, 15, 15)) }
      after { Timecop.return }

      it { expect(banco_ribeirao_preto.gera_arquivo).to eq(read_remessa('remessa-banco_ribeirao_preto-cnab240.rem', banco_ribeirao_preto.gera_arquivo)) }
    end
  end
end
