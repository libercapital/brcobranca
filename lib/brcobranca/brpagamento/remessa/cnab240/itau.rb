# -*- encoding: utf-8 -*-
#

module Brcobranca
  module Brpagamento
    module Remessa
      module Cnab240
        class Itau < Brcobranca::Brpagamento::Remessa::Cnab240::Base
          # heder arquivo
          attr_accessor :documento_debitado
          attr_accessor :agencia
          attr_accessor :empresa_mae
          attr_accessor :conta_corrente
          attr_accessor :digito_conta
          attr_accessor :densidade_gravacao

          # heder lote
          attr_accessor :logradouro
          attr_accessor :numero
          attr_accessor :complemento
          attr_accessor :cidade
          attr_accessor :cep
          attr_accessor :uf
          attr_accessor :finalidade_pagamento
          attr_accessor :forma_pagamento
          attr_accessor :tipo_pagamento


          validates_presence_of :documento_debitado, :agencia, :empresa_mae, :conta_corrente, :digito_conta, :logradouro, :numero, :cidade, :cep, :uf, :finalidade_pagamento, :forma_pagamento, :tipo_pagamento,
                                message: 'não pode estar em branco.'

          def initialize(campos = {})
            campos = { densidade_gravacao: '0',
                      finalidade_pagamento: '10',
                      forma_pagamento: '41',
                      tipo_pagamento: '98',
                      }.merge!(campos)
            super(campos)
          end

          def cod_banco
            '341'
          end

          def nome_banco
            'BANCO ITAU SA'.ljust(30, ' ')
          end

          # Header
          def versao_layout_arquivo
            '081'
          end

          def versao_layout_lote
            '040'
          end

          # Tipos de Pagamentos
          # 10 Dividendos
          # 15 Debêntures
          # 20 Fornecedores
          # 22 TRIBUTOS
          # 30 Salários
          # 40 Fundos de Investimentos
          # 50 Sinistros DE Seguros
          # 60 Despesas Viajante em Trânsito
          # 80 Representantes Autorizados
          # 90 Benefícios
          # 98 Diversos
          def tipo_do_pagamento
            tipo_pagamento.format_size(2)
          end

          # Formas de pagamento
          # 01 CRÉDITO EM CONTA CORRENTE NO ITAÚ
          # 02 CHEQUE PAGAMENTO/ADMINISTRATIVO
          # 03 DOC “C ”
          # 05 CRÉDITO EM CONTA POUPANÇA NO ITAÚ
          # 06 CRÉDITO EM CONTA CORRENTE DE MESMA TITULARIDADE
          # 07 DOC “D ”
          # 10 ORDEM DE PAGAMENTO À DISPOSIÇÃO
          # 11 ORDEM DE PAGAMENTO DE ACERTO – SOMENTE RETORNO - VER OBSERVAÇÃO ABAIXO
          # 13 PAGAMENTO DE CONCESSIONÁRIAS
          # 16 DARF NORMAL
          # 17 GPS - GUIA DA PREVIDÊNCIA SOCIAL
          # 18 DARF SIMPLES
          # 19 IPTU/ISS/OUTROS TRIBUTOS MUNICIPAIS
          # 21 DARJ
          # 22 GARE – SP ICMS
          # 25 IPVA
          # 27 DPVAT
          # 30 PAGAMENTO DE TÍTULOS EM COBRANÇA NO ITAÚ
          # 31 PAGAMENTO DE TÍTULOS EM COBRANÇA EM OUTROS BANCOS
          # 32 NOTA FISCAL – LIQUIDAÇÃO ELETRÔNICA
          # 35 FGTS – GFIP
          # 41 TED – OUTRO TITULAR
          # 43 TED – MESMO TITULAR
          # 60 CARTÃO SALÁRIO
          # 91 GNRE E TRIBUTOS COM CÓDIGO DE BARRAS
          def forma_do_pagamento
            forma_pagamento.format_size(2)
          end

          # Finalidade do pagamento
          # 01 Folha Mensal
          # 02 Folha Quinzenal
          # 03 Folha Complementar
          # 04 13o Salário
          # 05 Participação de Resultados
          # 06 Informe de Rendimentos
          # 07 Férias
          # 08 Rescisão
          # 09 Rescisão Complementar
          # 10 Outros
          # 85 Débito Conta Investimento
          def finalidade_do_pagamento
            finalidade_pagamento.format_size(30)
          end


          def endereco_completo
            endereco = ''                             # Descrição             Posição    Tamanho
            endereco << logradouro.format_size(30)    # ENDEREÇO DA EMPRESA   [143..172] 30(X)
            endereco << numero.format_size(5)         # NÚMERO DO ENDEREÇO    [173..177] 05(9)
            endereco << complemento.format_size(15)   # COMPLEMENTO           [178..192] 15(X)
            endereco << cidade.format_size(20)        # NOME DA CIDADE        [193..212] 20(X)
            endereco << cep.format_size(8)            # CEP                   [213..220] 08(9)
            endereco << uf.format_size(2)             # SIGLA DO ESTADO       [221..222] 02(X)
            endereco
          end

          # Data de geracao do arquivo
          #
          # @return [String]
          #
          def data_geracao
            Date.current.strftime('%d%m%Y')
          end

          # Hora de geracao do arquivo
          #
          # @return [String]
          #
          def hora_geracao
            Time.current.strftime('%H%M%S')
          end

          def counter_lotes(count, just = 4)
            count.to_s.rjust(just, '0')
          end

          # Monta o registro header do arquivo
          #
          # @return [String]
          #
          def monta_header_arquivo
            header_arquivo = ''                                                              # Descrição                              Posição    Tamanho
            header_arquivo << cod_banco                                                      # CÓDIGO DO BANCO                        [1......3] 03(9) 341
            header_arquivo << '0000'                                                         # CÓDIGO DO LOTE                         [4......7] 04(9) 0000
            header_arquivo << '0'                                                            # TIPO DE REGISTRO                       [8......8] 01(9) 0
            header_arquivo << ''.rjust(6, ' ')                                               # BRANCOS                                [9.....14] 06(X)
            header_arquivo << versao_layout_arquivo                                          # LAYOUT DE ARQUIVO                      [15....17] 03(9) 081
            header_arquivo << Util::Empresa.new(documento_debitado, false).tipo              # TIPO DE INSCRIÇÃO DA EMPRESA DEBITADA  [18....18] 01(9) 1 = CPF 2 = CNPJ
            header_arquivo << documento_debitado.to_s.rjust(14, '0')                         # CNPJ da EMPRESA DEBITADA               [19....32] 14(9)
            header_arquivo << ''.rjust(20, ' ')                                              # BRANCOS                                [33....52] 20(X)
            header_arquivo << agencia.rjust(5, '0')                                          # NÚMERO AGÊNCIA DEBITADA                [53....57] 05(9)
            header_arquivo << ''.rjust(1, ' ')                                               # BRANCOS                                [58....58] 01(X)
            header_arquivo << conta_corrente.ljust(12, ' ')                                  # CONTA NÚMERO DEBITADA                  [59....70] 12(9)
            header_arquivo << ''.rjust(1, ' ')                                               # BRANCOS                                [71....71] 01(X)
            header_arquivo << digito_conta                                                   # DAC DA AGÊNCIA/CONTA DEBITADA          [72....72] 01(9)
            header_arquivo << empresa_mae.format_size(30)                                    # NOME DA EMPRESA                        [73...102] 30(X)
            header_arquivo << nome_banco.format_size(30)                                     # NOME DO BANCO                          [103..132] 30(X)
            header_arquivo << ''.rjust(10, ' ')                                              # BRANCOS                                [133..142] 10(X)
            header_arquivo << '1'                                                            # CÓDIGO REMESSA/RETORNO                 [143..143] 01(9) 1=REMESSA
            header_arquivo << data_geracao                                                   # DATA DE GERAÇÃO DO ARQUIVO             [144..151] 08(9) DDMMAAAA
            header_arquivo << hora_geracao                                                   # HORA DE GERAÇÃO DO ARQUIVO             [152..157] 06(9) HHMMSS
            header_arquivo << ''.rjust(9, '0')                                               # ZEROS                                  [158..166] 09(9)
            header_arquivo << densidade_gravacao.rjust(9, '0')                               # DENSIDADE DE GRAVAÇÃO DO ARQUIVO       [167..171] 05(9) 0 Padrao | 1600 BPI | # 6250 BPI
            header_arquivo << ''.rjust(69, ' ')                                              # BRANCOS                                [172..240] 69(X)
            header_arquivo
          end

          # Monta o registro header do lotefinalidade_do_pagamento
          #
          # @param nro_lote [Integer]
          #   numero do lote no arquivo (iterar a cada novo lote)
          #
          # @return [String]
          #
          def monta_header_lote(nro_lote)
            header_lote = ''                                                                 # Descrição                                             Posição    Tamanho
            header_lote << cod_banco                                                         # CÓDIGO DO BANCO                                       [1......3] 03(9) 341
            header_lote << counter_lotes(nro_lote)                                           # CÓDIGO DO LOTE LOTE                                   [4......7] 04(9) NOTA 3
            header_lote << '1'                                                               # TIPO DE REGISTRO                                      [8......8] 01(9) 1
            header_lote << 'C'                                                               # TIPO DA OPERAÇÃO                                      [9......9] 01(X) C=CRÉDITO
            header_lote << tipo_do_pagamento                                                 # TIPO DE PAGAMENTO                                     [10....11] 02(9) NOTA 4
            header_lote << forma_do_pagamento                                                # FORMA DE PAGAMENTO                                    [12....13] 02(9) NOTA 5
            header_lote << versao_layout_lote                                                # LAYOUT DO LOTE                                        [14....16] 03(9) 040
            header_lote << ''.rjust(1, ' ')                                                  # BRANCOS                                               [17....17] 01(X)
            header_lote << Util::Empresa.new(documento_debitado, false).tipo                 # TIPO DE INSCRIÇÃO DA EMPRESA DEBITADA                 [18....18] 01(9) 1 = CPF2 = CNPJ
            header_lote << documento_debitado.to_s.rjust(14, '0')                            # CNPJ da EMPRESA DEBITADA                              [19....32] 14(9) NOTA 1
            header_lote << ''.rjust(4, '0')                                                  # IDENTIFICAÇÃO DO LANÇAMENTO NO EXTRATO DO FAVORECIDO  [33....36] 04(X) NOTA 13
            header_lote << ''.rjust(16, ' ')                                                 # BRANCOS                                               [37....52] 16(X)
            header_lote << agencia.rjust(5, '0')                                             # AGÊNCIA NÚMERO DEBITADA                               [53....57] 05(9) NOTA 1
            header_lote << ''.rjust(1, ' ')                                                  # BRANCOS                                               [58....58] 01(X)
            header_lote << conta_corrente.ljust(12, ' ')                                     # CONTA NÚMERO DEBITADA                                 [59....70] 12(9) NOTA 1
            header_lote << ''.rjust(1, ' ')                                                  # BRANCOS                                               [71....71] 01(X)
            header_lote << digito_conta                                                      # DAC DA AGÊNCIA/CONTA DEBITADA                         [72....72] 01(9) NOTA 1
            header_lote << empresa_mae.format_size(30)                                       # NOME DA EMPRESA DEBITADA                              [73...102] 30(X)
            header_lote << finalidade_do_pagamento                                           # FINALIDADE DOS PAGTOS DO LOTE                         [103..132] 30(X) NOTA 6
            header_lote << ''.rjust(10, ' ')                                                 # HISTÓRICO C/C DEBITADA                                [133..142] 10(X) NOTA 7
            header_lote << endereco_completo                                                 # endereco completo                                     [143..222]
            header_lote << ''.rjust(8, ' ')                                                  # BRANCOS                                               [223..230] 08(X)
            header_lote << ''.rjust(10, ' ')                                                 # OCORRÊNCIAS CÓDIGO OCORRÊNCIAS P/RETORNO              [231..240] 10(X) NOTA 8
            header_lote
          end

          # Monta o registro segmento A do arquivo
          #
          # @param pagamento [Brcobranca::Brpagamento::Remessa::Pagamento]
          #   objeto contendo os detalhes da ordem de pagamento
          # @param nro_lote [Integer]
          #   numero do lote que o segmento esta inserido
          # @param sequencial [Integer]
          #   numero sequencial do registro no lote
          #
          # @return [String]
          #
          def monta_segmento_a(pagamento, nro_lote, sequencial)
            segmento_a = ''                                                                  # Descrição                             Posição    Tamanho
            segmento_a << cod_banco                                                          # CÓDIGO DO BANCO                       [1......3] 03(9) 341
            segmento_a << counter_lotes(nro_lote)                                            # CÓDIGO DO LOTE                        [4......7] 04(9) NOTA 3
            segmento_a << '1'                                                                # TIPO DE REGISTRO                      [8......8] 01(9) 3
            segmento_a << sequencial.to_s.rjust(5, '0')                                      # SEQUENCIAL REGISTRO NO LOTE           [9.....13] 05(9) NOTA 9
            segmento_a << 'A'                                                                # SEGMENTO CÓDIGO                       [14....14] 01(X) A
            segmento_a << pagamento.tipo_de_movimento                                        # TIPO DE MOVIMENTO                     [15....17] 03(9) NOTA 10
            segmento_a << ''.rjust(3, '0')                                                   # CÂMARA                                [18....20] 03(9) NOTA 37
            segmento_a << pagamento.cod_banco                                                # CÓDIGO BANCO FAVORECIDO               [21....23] 03(9)
            segmento_a << pagamento.conta_bancaria_favorecido                                # CONTA BANCÁRIA FAVORECIDO             [24....43] 20(X) NOTA 11
            segmento_a << pagamento.nome_favorecido.format_size(30)                          # NOME DO FAVORECIDO                    [44....73] 30(X) NOTA 35
            segmento_a << pagamento.uso_da_empresa.format_size(20)                           # SEU NÚMERO                            [74....93] 20(X)
            segmento_a << pagamento.formata_data_pagamento('%d%m%Y')                         # DATA DE PAGTO                         [94...101] 08(9) DDMMAAAA
            segmento_a << pagamento.tipo_moeda                                               # TIPO DA MOEDA                         [102..104] 03(X) REA OU 009
            segmento_a << ''.rjust(8, '0')                                                   # CÓDIGO ISPB                           [105..112] 08(9) NOTA 37
            segmento_a << ''.rjust(7, '0')                                                   # ZEROS                                 [113..119] 07(9)
            segmento_a << pagamento.formata_valor(15)                                        # VALOR DO PAGTO                        [120..134] 13(9) V9(02)
            segmento_a << ''.ljust(15, ' ')                                                  # NOSSO NÚMERO                          [135..149] 15(X)
            segmento_a << ''.ljust(5, ' ')                                                   # BRANCOS                               [150..154] 05(X)
            segmento_a << ''.rjust(8, '0')                                                   # DATA EFETIVA - RETORNO                [155..162] 08(9)
            segmento_a << ''.rjust(15, '0')                                                  # VALOR EFETIVO                         [163..177] 13(9) V9(02)
            segmento_a << ''.ljust(18, ' ')                                                  # FINALIDADE DETALHE                    [178..195] 18(X) NOTA 13
            segmento_a << ''.ljust(2, ' ')                                                   # BRANCOS                               [196..197] 02(X)
            segmento_a << ''.rjust(6, '0')                                                   # NÚMERO DO DOCUMENTO                   [198..203] 06(9) NOTA 14
            segmento_a << pagamento.documento_favorecido.to_s.rjust(14, '0')                 # NÚMERO DE INSCRIÇÃO - (CPF/CNPJ)      [204..217] 14(9) NOTA 15
            segmento_a << ''.ljust(2, ' ')                                                   # FINALIDADE DOC E STATUS FUNCIONÁRIO   [218..219] 02(X) NOTA 30
            segmento_a << pagamento.finalidade_ted                                           # FINALIDADE TED                        [220..224] 05(X) NOTA 26
            segmento_a << ''.ljust(5, ' ')                                                   # BRANCOS                               [225..229] 05(X)
            segmento_a << pagamento.aviso_ao_favorecido                                      # AVISO AO FAVORECIDO                   [230..230] 01(X) NOTA 16
            segmento_a << ''.ljust(10, ' ')                                                  # CÓDIGO OCORRÊNCIAS NO RETORNO         [231..240] 10(X) NOTA 8
            segmento_a
          end

          # Monta o registro trailer do lote
          #
          # @param nro_lote [Integer]
          #   numero do lote no arquivo (iterar a cada novo lote)
          #
          # @param nro_registros [Integer]
          #   numero de registros(linhas) no lote (contando header e trailer)
          #
          # @return [String]
          #
          def monta_trailer_lote(nro_lote, nro_registros)
            trailer_lote = ''                                                                # Descrição                         Posição    Tamanho
            trailer_lote << cod_banco                                                        # CÓDIGO DO BANCO                   [1......3] 03(9) 341
            trailer_lote << counter_lotes(nro_lote)                                          # CÓDIGO DO LOTE                    [4......7] 04(9) NOTA 3
            trailer_lote << '5'                                                              # TIPO DE REGISTRO                  [8......8] 01(9) 5
            trailer_lote << ''.ljust(9, ' ')                                                 # BRANCOS COMPLEMENTO DE REGISTRO   [9.....17] 09(X)
            trailer_lote << nro_registros.to_s.rjust(6, '0')                                 # TOTAL QTDE REGISTROS              [18....23] 06(9) NOTA 17
            trailer_lote << valor_total_titulos(18)                                          # TOTAL VALOR PAGTOS                [24....41] 16(9)V9(2) NOTA 17
            trailer_lote << ''.rjust(18, '0')                                                # ZEROS                             [42....59] 18(9)
            trailer_lote << ''.rjust(171, ' ')                                               # BRANCOS                           [60...230] 171(X)
            trailer_lote << ''.rjust(10, ' ')                                                # OCORRÊNCIAS                       [231..240] 10(X) NOTA 8
            trailer_lote
          end

          # Monta o registro trailer do arquivo
          #
          # @param nro_lotes [Integer]
          #   numero de lotes no arquivo
          # @param sequencial [Integer]
          #   numero de registros(linhas) no arquivo
          #
          # @return [String]
          #
          def monta_trailer_arquivo(nro_lotes, sequencial)
            trailer_arquivo = ''                                                             # Descrição              Posição  Tamanho
            trailer_arquivo << cod_banco                                                     # CÓDIGO DO BANCO        [1.....3] 03(9) 341
            trailer_arquivo << '9999'                                                        # CÓDIGO DO LOTE         [4.....7] 04(9) 9999
            trailer_arquivo << '9'                                                           # TIPO DE REGISTRO       [8.....8] 01(9) 9
            trailer_arquivo << ''.rjust(9, ' ')                                              # BRANCOS                [9....17] 09(X)
            trailer_arquivo << counter_lotes(nro_lotes, 6)                                   # TOTAL QTDE DE LOTES    [18...23] 06(9) NOTA 17
            trailer_arquivo << sequencial.to_s.rjust(6, '0')                                 # TOTAL QTDE REGISTROS   [24...29] 06(9) NOTA 17
            trailer_arquivo << ''.rjust(211, ' ')                                            # BRANCOS                [30..240] 211(X)
            trailer_arquivo
          end

          # Monta um lote para o arquivo
          #
          # @param pagamento [Brcobranca::Brpagamento::Remessa::Pagamento]
          #   objeto contendo os detalhes do boleto (valor, )
          #
          # @param nro_lote [Integer]
          # numero do lote no arquivo
          #
          # @return [Array]
          #
          def monta_lote(nro_lote)
            # contador dos registros do lote
            contador = 1 # header

            lote = [monta_header_lote(nro_lote)]

            pagamentos.each do |pagamento|
              raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?

              lote << monta_segmento_a(pagamento, nro_lote, contador)
              contador += 1
            end

            contador += 1 # trailer
            lote << monta_trailer_lote(nro_lote, contador)

            lote
          end

          # Gera o arquivo remessa
          #
          # @return [String]
          #
          def gera_arquivo
            raise Brcobranca::RemessaInvalida, self if invalid?

            arquivo = [monta_header_arquivo]

            # contador de do lotes
            contador = 1
            arquivo.push monta_lote(contador)

            arquivo << monta_trailer_arquivo(contador, ((pagamentos.size * 2) + (contador * 2) + 2))

            remittance = arquivo.join("\r\n").to_ascii.upcase
            remittance << "\r\n"

            remittance.encode(remittance.encoding, universal_newline: true).encode(remittance.encoding, crlf_newline: true)
          end
        end
      end
    end
  end
end