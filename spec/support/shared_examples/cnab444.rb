# -*- encoding: utf-8 -*-
#
shared_examples_for 'cnab444' do
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

  let(:pagamento_com_campos_longos) do
    Brcobranca::Remessa::Pagamento.new(
      valor: 199.9,
      data_vencimento: Date.current,
      nosso_numero: 123,
      documento_sacado: '12345678901',
      documento_cedente: '12345678901234',
      nome_sacado: 'PABLO DIEGO JOSE FRANCISCO DE PAULA JUAN NEPOMUCENO REMEDIOS',
      nome_cedente: 'CEDENTE TESTE LTDA',
      endereco_sacado: 'RUA RIO GRANDE DO SUL',
      cep_sacado: '12345678',
      cidade_sacado: 'SAO PAULO',
      uf_sacado: 'SP',
      especie_titulo: '01',
      identificacao_ocorrencia: '01',
      coobrigacao: '01',
      uso_da_empresa: 'USO001',
      numero_documento: 'DOC001',
      n_nota_fiscal: '123456789',
      n_serie_nota_fiscal: 'SERIE_NOTA_MUITO_LONGA_QUE_EXCEDE_O_LIMITE',
      numero_termo_cessao: 'TERMO001',
      chave_nota: 'CHAVE_NFE_MUITO_LONGA_QUE_ULTRAPASSA_OS_QUARENTA_E_QUATRO_CARACTERES_PERMITIDOS'
    )
  end

  it 'header deve ter 444 posicoes' do
    expect(objeto.monta_header.size).to eq 444
  end

  it 'detalhe deve falhar se pagamento nao for valido' do
    expect { objeto.monta_detalhe(Brcobranca::Remessa::Pagamento.new, 1) }.to raise_error(Brcobranca::RemessaInvalida)
  end

  it 'detalhe deve ter 444 posicoes' do
    expect(objeto.monta_detalhe(pagamento, 1).size).to eq 444
  end

  it 'detalhe deve ter exatamente 444 posicoes mesmo com campos acima do tamanho maximo' do
    expect(objeto.monta_detalhe(pagamento_com_campos_longos, 1).size).to eq 444
  end

  context 'trailer' do
    it 'trailer deve ter 444 posicoes' do
      expect(objeto.monta_trailer(1).size).to eq 444
    end

    it 'informacoes devem estar posicionadas corretamente no trailer' do
      trailer = objeto.monta_trailer(3)
      expect(trailer[0]).to eq '9'
      expect(trailer[438..443]).to eq '000003'
    end
  end

  it 'montagem da remessa deve falhar se o objeto nao for valido' do
    expect { subject.class.new.gera_arquivo }.to raise_error(Brcobranca::RemessaInvalida)
  end
end
