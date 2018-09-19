# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Remessa
    class Pagamento
      # Validações do Rails 3
      include ActiveModel::Validations

      # <b>REQUERIDO</b>: nosso numero
      attr_accessor :nosso_numero
      # <b>REQUERIDO</b>: data do vencimento do boleto
      attr_accessor :data_vencimento
      # <b>REQUERIDO</b>: data de emissao do boleto
      attr_accessor :data_emissao
      # <b>REQUERIDO</b>: valor do boleto
      attr_accessor :valor
      # <b>REQUERIDO</b>: documento do sacado (cliente)
      attr_accessor :documento_sacado
      # <b>REQUERIDO</b>: nome do sacado (cliente)
      attr_accessor :nome_sacado
      # <b>REQUERIDO</b>: endereco do sacado (cliente)
      attr_accessor :endereco_sacado
      # <b>REQUERIDO</b>: bairro do sacado (cliente)
      attr_accessor :bairro_sacado
      # <b>REQUERIDO</b>: CEP do sacado (cliente)
      attr_accessor :cep_sacado
      # <b>REQUERIDO</b>: cidade do sacado (cliente)
      attr_accessor :cidade_sacado
      # <b>REQUERIDO</b>: UF do sacado (cliente)
      attr_accessor :uf_sacado
      # <b>REQUERIDO</b>: Código da ocorrência
      attr_accessor :identificacao_ocorrencia
      # <b>OPCIONAL</b>: Tipo Empresa
      attr_accessor :tipo_empresa
      # <b>OPCIONAL</b>: documento empresa
      attr_accessor :documento_empresa
      # <b>OPCIONAL</b>: nome do avalista
      attr_accessor :nome_avalista
      # <b>OPCIONAL</b>: documento do avalista
      attr_accessor :documento_avalista
      # <b>REQUERIDO</b>: endereco do sacado (cliente)
      attr_accessor :endereco_avalista
      # <b>REQUERIDO</b>: bairro do sacado (cliente)
      attr_accessor :bairro_avalista
      # <b>REQUERIDO</b>: CEP do sacado (cliente)
      attr_accessor :cep_avalista
      # <b>REQUERIDO</b>: cidade do sacado (cliente)
      attr_accessor :cidade_avalista
      # <b>REQUERIDO</b>: UF do sacado (cliente)
      attr_accessor :uf_avalista
      # <b>OPCIONAL</b>: codigo da 1a instrucao
      attr_accessor :cod_primeira_instrucao
      # <b>OPCIONAL</b>: codigo da 2a instrucao
      attr_accessor :cod_segunda_instrucao
      # <b>OPCIONAL</b>: valor da mora ao dia
      attr_accessor :valor_mora
      # <b>OPCIONAL</b>: data limite para o desconto
      attr_accessor :data_desconto
      # <b>OPCIONAL</b>: valor a ser concedido de desconto
      attr_accessor :valor_desconto
      # <b>OPCIONAL</b>: codigo do desconto (para CNAB240)
      attr_accessor :cod_desconto
      # <b>OPCIONAL</b>: valor do IOF
      attr_accessor :valor_iof
      # <b>OPCIONAL</b>: valor do abatimento
      attr_accessor :valor_abatimento
      # <b>OPCIONAL</b>: Número do Documento de Cobrança - Número adotado e controlado pelo Cliente,
      # para identificar o título de cobrança.
      # Informação utilizada para referenciar a identificação do documento objeto de cobrança.
      # Poderá conter número de duplicata, no caso de cobrança de duplicatas; número da apólice,
      # no caso de cobrança de seguros, etc
      attr_accessor :numero_documento
      # <b>OPCIONAL</b>: data limite para o desconto
      attr_accessor :data_segundo_desconto
      # <b>OPCIONAL</b>: valor a ser concedido de desconto
      attr_accessor :valor_segundo_desconto
      # <b>OPCIONAL</b>: espécie do título
      attr_accessor :especie_titulo
      # <b>OPCIONAL</b>: código da multa
      attr_accessor :codigo_multa
      # <b>OPCIONAL</b>: Percentual multa por atraso %
      attr_accessor :percentual_multa
      # <b>OPCIONAL</b>: Data para cobrança de multa
      attr_accessor :data_multa
      # <b>OPCIONAL</b>: Número da Parcela
      attr_accessor :parcela
      # <b>OPCIONAL</b>: Dias para o protesto
      attr_accessor :dias_protesto
      # <b>OPCIONAL</b>: de livre utilização pela empresa, cuja informação não é consistida pelo Itaú, e não
      # sai no aviso de cobrança, retornando ao beneficiário no arquivo retorno em qualquer movimento do título
      # (baixa, liquidação, confirmação de protesto, etc.) com o mesmo conteúdo da entrada.
      attr_accessor :uso_da_empresa

      attr_accessor :mensagem

      # CNAB 444
      # <b>REQUERIDO</b>: coobrigacao
      # 01 =Com Coobrigação 02 = Sem Coobrigação
      attr_accessor :coobrigacao
      # <b>REQUERIDO</b>: nome do cedente
      attr_accessor :nome_cedente
      # <b>REQUERIDO</b>: documento do cedente
      attr_accessor :documento_cedente

      attr_accessor :caracteristica_especial
      attr_accessor :modalidade_operacao
      # Mod  Descrição
      # 0301 desconto de duplicatas
      # 0302 desconto de cheques
      # 0303 antecipação de fatura de cartão de crédito
      # 0398 outros direitos creditórios descontados
      # 0399 outros títulos descontados
      attr_accessor :natureza_operacao
      # Domínio Descrição
      # 02      Operações adquiridas em negociação com pessoa integrante do SFN sem retenção substancial de risco e de benefícios ou de controle pelo interveniente ou cedente
      # 03      Operações adquiridas em negociação com pessoa não integrante do SFN sem retenção substancial de risco e de benefícios ou de controle pelo interveniente ou cedente
      # 04      Operações adquiridas em negociação com pessoa integrante do SFN com retenção substancial de risco e de benefícios ou de controle pelo interveniente ou cedente
      attr_accessor :origem_recurso
      # Recursos livres
      # Descrição Mod Descrição
      # 0101      não liberados
      # 0102      repasses do exterior
      # 0199      outros
      #
      # Recursos direcionados
      # Descrição Mod Descrição
      # 0201      não liberados
      # 0202      BNDES - Banco Nacional de Desenvolvimento Econômico e Social
      # 0203      Finame - Agência Especial de Financiamento Industrial
      # 0204      FCO - Fundo Constitucional do Centro Oeste
      # 0205      FNE - Fundo Constitucional do Nordeste
      # 0206      FNO - Fundo Constitucional do Norte
      # 0207      fundos estaduais ou distritais
      # 0208      recursos captados em depósitos de poupança pelas entidades integrantes do SBPE destinados a operações de financiamento imobiliário
      # 0209      financiamentos concedidos ao amparo de recursos controlados do crédito rural
      # 0210      repasses de organismos multilaterais no exterior
      # 0211      outros repasses do exterior
      # 0212      fundos ou programas especiais do governo federal
      # 0213      FGTS – Fundo de Garantia do Tempo de Serviço
      # 0299      outros
      attr_accessor :classe_risco_operacao
      # Domínio Descrição
      # AA      Classificação de risco AA
      # A       Classificação de risco A
      # B       Classificação de risco B
      # C       Classificação de risco C
      # D       Classificação de risco D
      # E       Classificação de risco E
      # F       Classificação de risco F
      # G       Classificação de risco G
      # H       Classificação de risco H
      # HH      Classificação de risco HH - créditos baixados como prejuízo
      attr_accessor :especie_titulo
      # 01 - Duplicata
      # 02 - Nota Promissória
      # 06 - Nota Promissória Física
      # 12 - Duplicata de Serviço
      # 14 - Duplicata de Serviço Física
      # 51 - Cheque
      # 60 - Contrato
      # 61 - Contrato Físico
      # 65 - Fatura de Cartão Credito
      attr_accessor :numero_termo_cessao
      attr_accessor :valor_aquisicao
      attr_accessor :valor_abatimento
      attr_accessor :n_nota_fiscal
      attr_accessor :n_serie_nota_fiscal
      attr_accessor :chave_nota

      validates_presence_of :nosso_numero, :data_vencimento, :valor,
                            :documento_sacado, :nome_sacado, :endereco_sacado,
                            :cep_sacado, :cidade_sacado, :uf_sacado, message: 'não pode estar em branco.'
      validates_length_of :uf_sacado, is: 2, message: 'deve ter 2 dígitos.'
      validates_length_of :cep_sacado, is: 8, message: 'deve ter 8 dígitos.'
      validates_length_of :cod_desconto, is: 1, message: 'deve ter 1 dígito.'
      validates_length_of :especie_titulo, is: 2, message: 'deve ter 2 dígitos.', allow_blank: true
      validates_length_of :identificacao_ocorrencia, is: 2, message: 'deve ter 2 dígitos.'
      validates_length_of :uso_da_empresa, maximum: 25, message: 'deve ter no máximo 25 dígitos.', allow_blank: true, default: ''

      # Nova instancia da classe Pagamento
      #
      # @param campos [Hash]
      #
      def initialize(campos = {})
        padrao = {
          data_emissao: Date.current,
          valor_mora: 0.0,
          valor_desconto: 0.0,
          valor_segundo_desconto: 0.0,
          valor_iof: 0.0,
          valor_abatimento: 0.0,
          valor_aquisicao: 0.0,
          nome_avalista: '',
          cod_desconto: '0',
          especie_titulo: '01',
          identificacao_ocorrencia: '01',
          codigo_multa: '0',
          percentual_multa: 0.0,
          parcela: '01',

          # CNAB 444
          caracteristica_especial: "35", # operações cedidas nos termos da resolução 3.533/08.
          modalidade_operacao: "0301", # esta dentro de "Direitos creditórios descontados",todas as remessas tem a mesma operação "Direitos creditórios descontados"?
          natureza_operacao: "02", # Operações adquiridas em negociação com pessoa integrante do SFN sem retenção substancial de risco e de benefícios ou de controle pelo interveniente ou cedente
          origem_recurso: "0199", # outros
          classe_risco_operacao: "AA", # Classificação de risco AA

        }

        campos = padrao.merge!(campos)
        campos.each do |campo, valor|
          send "#{campo}=", valor
        end

        yield self if block_given?
      end


      # CNAB 444
      def formata_endereco_sacado(pgto)
        endereco = "#{pgto.endereco_sacado}, #{pgto.cidade_sacado}/#{pgto.uf_sacado}"
        return endereco.ljust(40, ' ') if endereco.size <= 40
        "#{pgto.endereco_sacado[0..19]} #{pgto.cidade_sacado[0..14]}/#{pgto.uf_sacado}".format_size(40)
      end

      # Formata a data de desconto de acordo com o formato passado
      #
      # @return [String]
      #
      def formata_data_desconto(formato = '%d%m%y')
        data_desconto.strftime(formato)
      rescue
        if formato == '%d%m%y'
          '000000'
        else
          '00000000'
        end
      end

      # Formata a data de segundo desconto de acordo com o formato passado
      #
      # @return [String]
      #
      def formata_data_segundo_desconto(formato = '%d%m%y')
        data_segundo_desconto.strftime(formato)
      rescue
        if formato == '%d%m%y'
          '000000'
        else
          '00000000'
        end
      end

      # Formata a data de cobrança da multa
      #
      # @return [String]
      #
      def formata_data_multa(formato = '%d%m%y')
        data_multa.strftime(formato)
      rescue
        if formato == '%d%m%y'
          '000000'
        else
          '00000000'
        end
      end

      # Formata o campo valor
      # referentes as casas decimais
      # exe. R$199,90 => 0000000019990
      #
      # @param tamanho [Integer]
      #   quantidade de caracteres a ser retornado
      #
      def formata_valor(tamanho = 13)
        format_value(valor, tamanho)
      end

      # Formata o campo valor da mora
      #
      # @param tamanho [Integer]
      #   quantidade de caracteres a ser retornado
      #
      def formata_valor_mora(tamanho = 13)
        format_value(valor_mora, tamanho)
      end

      # Formata o campo valor da multa
      #
      # @param tamanho [Integer]
      #   quantidade de caracteres a ser retornado
      #
      def formata_valor_multa(tamanho = 6)
        format_value(percentual_multa, tamanho)
      end

      # Formata o campo valor do desconto
      #
      # @param tamanho [Integer]
      #   quantidade de caracteres a ser retornado
      #
      def formata_valor_desconto(tamanho = 13)
        format_value(valor_desconto, tamanho)
      end

      # Formata o campo valor do segundo desconto
      #
      # @param tamanho [Integer]
      #   quantidade de caracteres a ser retornado
      #
      def formata_valor_segundo_desconto(tamanho = 13)
        format_value(valor_segundo_desconto, tamanho)
      end

      # Formata o campo valor do IOF
      #
      # @param tamanho [Integer]
      #   quantidade de caracteres a ser retornado
      #
      def formata_valor_iof(tamanho = 13)
        format_value(valor_iof, tamanho)
      end

      # Formata o campo valor do IOF
      #
      # @param tamanho [Integer]
      #   quantidade de caracteres a ser retornado
      #
      def formata_valor_abatimento(tamanho = 13)
        format_value(valor_abatimento, tamanho)
      end

      def formata_valor_aquisicao(tamanho = 13)
        format_value(valor_aquisicao, tamanho)
      end

      # Retorna a identificacao do pagador
      # Se for pessoa fisica (CPF com 11 digitos) é 1
      # Se for juridica (CNPJ com 14 digitos) é 2
      #
      def identificacao_sacado(zero = true)
        Brcobranca::Util::Empresa.new(documento_sacado, zero).tipo
      end

      def identificacao_cedente(zero = true)
        Brcobranca::Util::Empresa.new(documento_cedente, zero).tipo
      end

      # Retorna a identificacao do avalista
      # Se for pessoa fisica (CPF com 11 digitos) é 1
      # Se for juridica (CNPJ com 14 digitos) é 2
      #
      def identificacao_avalista(zero = true)
        return '0' if documento_avalista.nil?
        Brcobranca::Util::Empresa.new(documento_avalista, zero).tipo
      end

      private

      def format_value(value, tamanho)
        raise ValorInvalido, 'Deve ser um Float' unless value.to_s =~ /\./

        sprintf('%.2f', value).delete('.').rjust(tamanho, '0')
      end
    end
  end
end
