# -*- encoding: utf-8 -*-
#

require 'spec_helper'

RSpec.describe Brcobranca::Remessa::Cnab444::Paulista do
  let(:pagamento) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 199.9,
      data_vencimento: Date.current,
      nosso_numero: 123,
      documento_sacado: '12345678901',
      documento_cedente: '12345678901234',
      nome_sacado: 'PABLO DIEGO JOSE FRANCISCO DE PAULA JUAN NEPOMUCENO REMEDIOS',
      nome_cedente: 'CEDENTE TESTE LTDA',
      endereco_sacado: 'RUA RIO GRANDE DO SUL Sao paulo Minas cacapa da silva junior',
      bairro_sacado: 'Sao jose dos quatro apostolos magros',
      cep_sacado: '12345678',
      cidade_sacado: 'Santa rita de cassia maria da silva',
      uf_sacado: 'SP',
      especie_titulo: '01',
      identificacao_ocorrencia: '01',
      coobrigacao: '01',
      uso_da_empresa: 'USO001',
      numero_documento: 'DOC001',
      n_nota_fiscal: '123456789',
      n_serie_nota_fiscal: '001',
      numero_termo_cessao: 'TERMO001',
      chave_nota: nil
    )
  end

  let(:params) do
    {
      agencia: '12345',
      conta_corrente: '1234567',
      empresa_mae: 'SOCIEDADE BRASILEIRA DE ZOOLOGIA LTDA',
      sequencial_remessa: '1',
      codigo_empresa: '12345678901234567890',
      pagamentos: [pagamento]
    }
  end

  let(:paulista) { subject.class.new(params) }
  let(:objeto) { paulista }

  context 'validacoes dos campos' do
    it 'deve ser invalido sem tipo_registro' do
      objeto = subject.class.new(params.merge(tipo_registro: nil))
      expect(objeto.invalid?).to be true
      expect(objeto.errors.full_messages).to include('Tipo registro não pode estar em branco.')
    end

    it 'deve ser invalido sem coobrigacao' do
      objeto = subject.class.new(params.merge(coobrigacao: nil))
      expect(objeto.invalid?).to be true
      expect(objeto.errors.full_messages).to include('Coobrigacao não pode estar em branco.')
    end

    it 'deve ser invalido sem primeira_instrucao' do
      objeto = subject.class.new(params.merge(primeira_instrucao: nil))
      expect(objeto.invalid?).to be true
      expect(objeto.errors.full_messages).to include('Primeira instrucao não pode estar em branco.')
    end

    it 'deve ser invalido sem segunda_instrucao' do
      objeto = subject.class.new(params.merge(segunda_instrucao: nil))
      expect(objeto.invalid?).to be true
      expect(objeto.errors.full_messages).to include('Segunda instrucao não pode estar em branco.')
    end
  end

  context 'formatacoes dos valores' do
    it 'cod_banco deve ser 611' do
      expect(paulista.cod_banco).to eq '611'
    end

    it 'nome_banco deve ser PAULISTA S.A. com 15 posicoes' do
      nome_banco = paulista.nome_banco
      expect(nome_banco.size).to eq 15
      expect(nome_banco.strip).to eq 'PAULISTA S.A.'
    end
  end

  context 'monta remessa' do
    it_behaves_like 'cnab444'

    context 'header' do
      it 'informacoes devem estar posicionadas corretamente no header' do
        header = paulista.monta_header
        expect(header[1]).to eq '1'
        expect(header[2..8]).to eq 'REMESSA'
        expect(header[76..78]).to eq '611'
      end
    end

    context 'detalhe' do
      it 'informacoes devem estar posicionadas corretamente no detalhe' do
        detalhe = paulista.monta_detalhe(pagamento, 1)
        expect(detalhe[0]).to eq '1'                          # tipo_registro
        expect(detalhe[218..219]).to eq '01'                  # identificacao_sacado (CPF)
        expect(detalhe[220..233]).to eq '00012345678901'      # documento_sacado (14 chars)
        expect(detalhe[314..322]).to eq '123456789'           # n_nota_fiscal
        expect(detalhe[438..443]).to eq '000001'              # sequencial
      end

      it 'detalhe deve ter exatamente 444 posicoes com n_serie_nota_fiscal longa' do
        pagamento_longo = Brcobranca::Remessa::Pagamento.new(
          valor: 199.9, data_vencimento: Date.current, nosso_numero: 123,
          documento_sacado: '12345678901', documento_cedente: '12345678901234',
          nome_sacado: 'PABLO DIEGO JOSE', nome_cedente: 'CEDENTE LTDA',
          endereco_sacado: 'RUA RIO GRANDE', cep_sacado: '12345678',
          cidade_sacado: 'SAO PAULO', uf_sacado: 'SP',
          especie_titulo: '01', identificacao_ocorrencia: '01',
          coobrigacao: '01', uso_da_empresa: 'USO001',
          numero_documento: 'DOC001', numero_termo_cessao: 'TERMO001',
          n_nota_fiscal: '123456789',
          n_serie_nota_fiscal: 'SERIE_MUITO_LONGA_QUE_EXCEDE_3_CHARS'
        )
        expect(paulista.monta_detalhe(pagamento_longo, 1).size).to eq 444
      end

      it 'detalhe deve ter exatamente 444 posicoes com chave_nota longa' do
        pagamento_longo = Brcobranca::Remessa::Pagamento.new(
          valor: 199.9, data_vencimento: Date.current, nosso_numero: 123,
          documento_sacado: '12345678901', documento_cedente: '12345678901234',
          nome_sacado: 'PABLO DIEGO JOSE', nome_cedente: 'CEDENTE LTDA',
          endereco_sacado: 'RUA RIO GRANDE', cep_sacado: '12345678',
          cidade_sacado: 'SAO PAULO', uf_sacado: 'SP',
          especie_titulo: '01', identificacao_ocorrencia: '01',
          coobrigacao: '01', uso_da_empresa: 'USO001',
          numero_documento: 'DOC001', numero_termo_cessao: 'TERMO001',
          n_nota_fiscal: '123456789', n_serie_nota_fiscal: '001',
          chave_nota: 'CHAVE_NFE_MUITO_LONGA_QUE_ULTRAPASSA_OS_QUARENTA_E_QUATRO_CARACTERES_PERMITIDOS'
        )
        expect(paulista.monta_detalhe(pagamento_longo, 1).size).to eq 444
      end

      it 'detalhe deve ter exatamente 444 posicoes com documento_cedente longo' do
        pagamento_longo = Brcobranca::Remessa::Pagamento.new(
          valor: 199.9, data_vencimento: Date.current, nosso_numero: 123,
          documento_sacado: '12345678901', documento_cedente: '1234567890123456789',
          nome_sacado: 'PABLO DIEGO JOSE', nome_cedente: 'CEDENTE LTDA',
          endereco_sacado: 'RUA RIO GRANDE', cep_sacado: '12345678',
          cidade_sacado: 'SAO PAULO', uf_sacado: 'SP',
          especie_titulo: '01', identificacao_ocorrencia: '01',
          coobrigacao: '01', uso_da_empresa: 'USO001',
          numero_documento: 'DOC001', numero_termo_cessao: 'TERMO001',
          n_nota_fiscal: '123456789', n_serie_nota_fiscal: '001',
          chave_nota: nil
        )
        expect(paulista.monta_detalhe(pagamento_longo, 1).size).to eq 444
      end
    end
  end
end
