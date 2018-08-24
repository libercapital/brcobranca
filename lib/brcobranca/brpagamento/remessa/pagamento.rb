# -*- encoding: utf-8 -*-
#

module Brcobranca
  module Brpagamento
    module Remessa
      class Pagamento
        # Validações do Rails 3
        include ActiveModel::Validations

        # <b>REQUERIDO</b>: código do banco
        attr_accessor :cod_banco
        # <b>REQUERIDO</b>: tipo do movimento
        attr_accessor :tipo_movimento
        # <b>REQUERIDO</b>: Agência creditada
        attr_accessor :agencia
        # <b>REQUERIDO</b>: Conta Crrente creditada
        attr_accessor :conta_corrente
        # <b>REQUERIDO</b>: Digito verificado da Conta Crrente creditada
        attr_accessor :digito_conta
        # <b>REQUERIDO</b>: Nome do Favorecido
        attr_accessor :nome_favorecido
        # <b>REQUERIDO</b>: Documento do Favorecido
        attr_accessor :documento_favorecido
        # <b>REQUERIDO</b>: Uso da Empresa
        attr_accessor :documento
        # <b>REQUERIDO</b>: Data do Pagamento
        attr_accessor :data_pagamento
        # <b>REQUERIDO</b>: Tipo da moeda
        attr_accessor :tipo_moeda
        # <b>REQUERIDO</b>: Valor do pagamento
        attr_accessor :valor
        # <b>REQUERIDO</b>: Finalidade Ted
        attr_accessor :finalidade_ted
        # <b>REQUERIDO</b>: aviso ao Favorecido
        attr_accessor :aviso_favorecido

        validates_presence_of :cod_banco, :tipo_movimento, :agencia, :conta_corrente, :digito_conta, :nome_favorecido, :documento_favorecido, :documento, :data_pagamento, :tipo_moeda, :valor, :finalidade_ted, :aviso_favorecido,
                              message: 'não pode estar em branco.'

        validates_length_of :cod_banco, is: 3, message: 'deve ter 3 dígitos.'
        validates_length_of :digito_conta, is: 1, message: 'deve ter apenas 1 dígito.'

        # Nova instancia da classe Pagamento
        #
        # @param campos [Hash]
        #
        def initialize(campos = {})
          padrao = {
            tipo_moeda: '009',
            tipo_movimento: '000',
            aviso_favorecido: '0',
            finalidade_ted: '00010'
          }

          campos = padrao.merge!(campos)
          campos.each { |campo, valor| send "#{campo}=", valor }

          yield self if block_given?
        end

        # Cnab 240
        # Código Descrição
        # 00001 Pagamento de Impostos, Tributos e Taxas
        # 00002 Pagamento a Concessionárias de Serviço Público
        # 00003 Pagamento de Dividendos
        # 00004 Pagamento de Salários
        # 00005 Pagamento de Fornecedores
        # 00006 Pagamento de Honorários
        # 00007 Pagamento de Aluguéis e Taxas e Condomínio
        # 00008 Pagamento de Duplicatas e Títulos
        # 00009 Pagamento de Honorários
        # 00010 Crédito em Conta
        # 00011 Pagamento a Corretoras
        # 00016 Crédito em Conta Investimento
        # 00100 Depósito Judicial
        # 00101 Pensão Alimentícia
        # 00200 Transferência Internacional de Reais
        # 00201 Ajuste Posição Mercado Futuro
        # 00204 Compra/Venda de Ações – Bolsas de Valores e Mercado de Balcão
        # 00205 Contrato referenciado em Ações/Índices de Ações – BV/BMF
        # 00300 Restituição de Imposto de Renda
        # 00500 Restituição de Prêmio de Seguros
        # 00501 Pagamento de indenização de Sinistro de Seguro
        # 00502 Pagamento de Prêmio de Co-seguro
        # 00503 Restituição de prêmio de Co-seguro
        # 00504 Pagamento de indenização de Co-seguro
        # 00505 Pagamento de prêmio de Resseguro
        # 00506 Restituição de prêmio de Resseguro
        # 00507 Pagamento de Indenização de Sinistro de Resseguro
        # 00508 Restituição de Indenização de Sinistro de Resseguro
        # 00509 Pagamento de Despesas com Sinistros
        # 00510 Pagamento de Inspeções/Vistorias Prévias
        # 00511 Pagamento de Resgate de Título de Capitalização
        # 00512 Pagamento de Sorteio de Título de Capitalização
        # 00513 Pagamento de Devolução de Mensalidade de Título de Capitalização
        # 00514 Restituição de Contribuição de Plano Previdenciário
        # 00515 Pagamento de Benefício Previdenciário de Pecúlio
        # 00516 Pagamento de Benefício Previdenciário de Pensão
        # 00517 Pagamento de Benefício Previdenciário de Aposentadoria
        # 00518 Pagamento de Resgate Previdenciário
        # 00519 Pagamento de Comissão de Corretagem
        # 00520 Pagamento de Transferências/Portabilidade de Reserva de Seguro/Previdência
        def finalidade_da_ted
          finalidade_ted.rjust(5, '0')
        end

        # Se igual a ‘0’ não emite aviso ao favorecido;
        # Se igual a ‘3’ emite aviso ao favorecido quando do agendamento do pagamento, sendo obrigatória a existência de um registro com segmento B.
        # Se igual a ‘5’ e mite aviso ao favorecido após pagamento efetuado, sendo obrigatória a existência de um registro com segmento B.
        # Se igual a ‘9’ emite aviso ao favorecido tanto no agendamento quanto após o pagamento, sendo obrigatória a existência de um registro com segmento B.
        #
        # Observação: Apenas serão emitidos avisos para os tipos de pagamentos 20 (fornecedores) ou 98 (diversos) e para as formas abaixo, conforme segue:
        # --------------------------------------- #
        # Forma (nota 5) No Agend. Após Pagamento #
        # --------------------------------------- #
        # 00             NÃO       NÃO            #
        # --------------------------------------- #
        # 01             SIM       SIM            #
        # --------------------------------------- #
        # 02             SIM       SIM            #
        # --------------------------------------- #
        # 03             SIM       SIM            #
        # --------------------------------------- #
        # 05             SIM       NÃO            #
        # --------------------------------------- #
        # 06             SIM       NÃO            #
        # --------------------------------------- #
        # 07             SIM       NÃO            #
        # --------------------------------------- #
        # 10             SIM       NÃO            #
        # --------------------------------------- #
        # 41             SIM       SIM            #
        # --------------------------------------- #
        # 43             SIM       SIM            #
        # --------------------------------------- #
        def aviso_ao_favorecido
          aviso_favorecido.rjust(1, '0')
        end

        # Tipo de movimento
        # 000 Inclusão de pagamento
        # 001 CPF
        # 002 CNPJ (completo)
        # 003 CNPJ (raiz)
        # 004 Inclusão de Demonstrativo Pagamento/Holerite
        # 512 Alteração do Demonstrativo de Pagamentos/Holerite
        # 517 Alteração de Valor do Pagamento
        # 519 Alteração da Data de Pagamento
        # 998 Exclusão do Demonstrativo de Pagamentos/Holerite
        # 999 Exclusão de pagamento incluído anteriormente
        def tipo_de_movimento
          tipo_movimento.rjust(3, '0')
        end

        # Formata a data de pagamento
        #
        # @return [String]
        #
        def formata_data_pagamento(formato = '%d%m%y')
          data_pagamento.strftime(formato)
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

        # Descrição                            Posição    Tamanho

        def conta_bancaria_favorecido
          conta = ''                                           # Descrição                         Posição  Tamanho
          if
            conta << agencia.rjust(5, '0')                     # AGÊNCIA NÚMERO FAVORECIDO         [24..28] 05(9)
            conta << ''.ljust(1, ' ')                          # BRANCOS                           [29..29] 01(X)
            conta << conta_corrente.rjust(12, '0')             # CONTA NÚMERO FAVORECIDO           [30..41] 12(9)
            conta << ''.ljust(1, ' ')                          # BRANCOS                           [42..42] X(01)
            conta << ''.ljust(1, ' ')                          # DAC DA AGÊNCIA/CONTA FAVORECIDO   [43..43] 01(X)
          else
            conta << ''.rjust(1, '0')                          # ZEROS                             [24..24] 01(9)
            conta << agencia.rjust(4, '0')                     # AGÊNCIA NÚMERO FAVORECIDO         [25..28] 04(9)
            conta << ''.ljust(1, ' ')                          # BRANCOS                           [29..29] 01(X)
            conta << ''.ljust(6, ' ')                          # ZEROS                             [30..35] 06(9)
            conta << conta_corrente.rjust(6, '0')              # CONTA NÚMERO FAVORECIDO           [36..41] 06(9)
            conta << ''.ljust(1, ' ')                          # BRANCOS                           [42..42] 01(X)
            conta << digito_conta                              # DAC DA AGÊNCIA/CONTA FAVORECIDO   [43..43] 01(9)
          end
        end

        private

        def format_value(value, tamanho)
          raise ValorInvalido, 'Deve ser um Float' unless value.to_s =~ /\./

          sprintf('%.2f', value).delete('.').rjust(tamanho, '0')
        end
      end
    end
  end
end