# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Remessa
    module Cnab400
      class Bradesco < Brcobranca::Remessa::Cnab400::Base
        # codigo da empresa (informado pelo Bradesco no cadastramento)
        attr_accessor :codigo_empresa

        attr_accessor :condicao_emissao
        # 1 Banco emite e Processa o registro
        # 2 Cliente emite e o Banco somente processa o registro

        attr_accessor :identificacao_registro
        # N Não registra na cobrança
        # Diferente de N registra e emite Boleto

        attr_accessor :aviso_debito
        # 1 emite aviso,e assume o endereço do Pagadorconstante do Arquivo-Remessa
        # 2 não emite aviso

        # attr_accessor :especie_titulo
        # 01 Duplicata
        # 02 Nota Promissória
        # 03 Nota de Seguro
        # 04 Cobrança Seriada
        # 05 Recibo
        # 10 Letras de Câmbio
        # 11 Nota de Débito
        # 12 Duplicata de Serv
        # 30 Boleto de Proposta
        # 99 Outros

        attr_accessor :primeira_instrucao
        attr_accessor :instrucao_cobranca
        attr_accessor :campo_multa

        validates_presence_of :agencia, :conta_corrente, message: 'não pode estar em branco.'
        validates_presence_of :codigo_empresa, :sequencial_remessa,
                              :digito_conta, message: 'não pode estar em branco.'
        validates_length_of :codigo_empresa, maximum: 20, message: 'deve ser menor ou igual a 20 dígitos.'
        validates_length_of :agencia, maximum: 5, message: 'deve ter 5 dígitos.'
        validates_length_of :conta_corrente, maximum: 7, message: 'deve ter 7 dígitos.'
        validates_length_of :sequencial_remessa, maximum: 7, message: 'deve ter 7 dígitos.'
        validates_length_of :carteira, maximum: 2, message: 'deve ter no máximo 2 dígitos.'
        validates_length_of :digito_conta, maximum: 1, message: 'deve ter 1 dígito.'

        def initialize(campos = {})
          campos = { condicao_emissao: '1', aviso_debito: '2', identificacao_registro: 'N', primeira_instrucao: '00', instrucao_cobranca: '05', campo_multa: '2' }.merge!(campos)
          super(campos)
        end

        def gera_arquivo
          raise Brcobranca::RemessaInvalida, self unless valid?

          # contador de registros no arquivo
          contador = 1
          ret = [monta_header]
          pagamentos.each do |pagamento|
            contador += 1
            ret << monta_detalhe(pagamento, contador)
            if pagamento.nome_avalista.present? && pagamento.documento_avalista.present?
              contador += 1
              ret << monta_detalhe_avalista(pagamento, contador)
            end
          end
          ret << monta_trailer(contador + 1)

          remittance = ret.join("\n").unicode_normalize(:nfkd).encode('ASCII', invalid: :replace, undef: :replace, replace: '').upcase
          remittance << "\n"

          remittance.encode(remittance.encoding, universal_newline: true).encode(remittance.encoding, crlf_newline: true)
        end

        def monta_documento_avalista(documento)
          case Brcobranca::Util::Empresa.new(documento).tipo
          when "01"
            length = pagamento.documento_avalista.length
            "#{documento[0..length-3]}0000#{documento[length-2..length-0]}".format_size(15)
          when "02"
            documento.rjust(15, '0').format_size(15)
          end
        end

        def agencia=(valor)
          @agencia = valor.to_s.rjust(5, '0') if valor
        end

        def conta_corrente=(valor)
          @conta_corrente = valor.to_s.rjust(7, '0') if valor
        end

        def codigo_empresa=(valor)
          @codigo_empresa = valor.to_s.rjust(20, '0') if valor
        end

        def sequencial_remessa=(valor)
          @sequencial_remessa = valor.to_s.rjust(7, '0') if valor
        end

        def info_conta
          codigo_empresa
        end

        def cod_banco
          '237'
        end

        def nome_banco
          'BRADESCO'.ljust(15, ' ')
        end

        def complemento
          "#{''.rjust(8, ' ')}MX#{sequencial_remessa}#{''.rjust(277, ' ')}"
        end

        def identificacao_empresa
          # identificacao da empresa no banco
          identificacao = '0'                            # vazio                       [1]
          identificacao << carteira.to_s.rjust(3, '0')   # carteira                    [3]
          identificacao << agencia                       # codigo da agencia (sem dv)  [5]
          identificacao << conta_corrente                # codigo da conta             [7]
          identificacao << digito_conta                  # digito da conta             [1]
        end

        def digito_nosso_numero(nosso_numero)
          "#{carteira}#{nosso_numero.to_s.rjust(11, '0')}".modulo11(
            multiplicador: [2, 3, 4, 5, 6, 7],
            mapeamento: { 10 => 'P', 11 => 0 }
          ) { |total| 11 - (total % 11) }
        end

        # Formata o endereco do sacado
        # de acordo com os caracteres disponiveis (40)
        # concatenando o endereco, cidade e uf
        #
        def formata_endereco_sacado(pgto)
          endereco = "#{pgto.endereco_sacado}, #{pgto.cidade_sacado}/#{pgto.uf_sacado}"
          return endereco.ljust(40, ' ') if endereco.size <= 40
          "#{pgto.endereco_sacado[0..19]} #{pgto.cidade_sacado[0..14]}/#{pgto.uf_sacado}".format_size(40)
        end

        def monta_detalhe(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?
          detalhe = '1'                                               # identificacao do registro                   9[01]       001 a 001
          detalhe << ''.rjust(5, '0')                                 # agencia de debito (op)                      9[05]       002 a 006
          detalhe << ''.rjust(1, '0')                                 # digito da agencia de debito (op)            X[01]       007 a 007
          detalhe << ''.rjust(5, '0')                                 # razao da conta corrente de debito (op)      9[05]       008 a 012
          detalhe << ''.rjust(7, '0')                                 # conta corrente (op)                         9[07]       013 a 019
          detalhe << ''.rjust(1, '0')                                 # digito da conta corrente (op)               X[01]       020 a 020
          detalhe << identificacao_empresa                            # identficacao da empresa                     X[17]       021 a 037
          detalhe << pagamento.uso_da_empresa.to_s.rjust(25, ' ')           # identificacao do tit. na empresa      X[25]       038 a 062
          detalhe << ''.rjust(3, '0')                                 # codigo do banco (debito automatico apenas)  9[03]       063 a 065
          detalhe << campo_multa.rjust(1, '0')                        # campo da multa                              9[01]       066 a 066 *
          detalhe << pagamento.percentual_multa.rjust(4, '0')         # percentual multa  00,00                     9[04]       067 a 070 *
          detalhe << pagamento.nosso_numero.to_s.rjust(11, '0')       # identificacao do titulo (nosso numero)      9[11]       071 a 081
          detalhe << digito_nosso_numero(pagamento.nosso_numero).to_s # digito de conferencia do nosso numero (dv)  X[01]       082 a 082
          detalhe << ''.rjust(10, '0')                                # desconto por dia                            9[10]       083 a 092
          detalhe << condicao_emissao                                 # condicao emissao boleto (1 Banco |2 cliente)9[01]       093 a 093
          detalhe << identificacao_registro                           # emite boleto para debito                    X[01]       094 a 094
          detalhe << ''.rjust(10, ' ')                                # operacao no banco (brancos)                 X[10]       095 a 104
          detalhe << ' '                                              # indicador rateio                            X[01]       105 a 105
          detalhe << aviso_debito                                     # endereco para aviso debito (op 2 = ignora)  9[01]       106 a 106
          detalhe << ''.rjust(2, ' ')                                 # brancos                                     X[02]       107 a 108
          detalhe << pagamento.identificacao_ocorrencia               # identificacao ocorrencia                    9[02]       109 a 110
          detalhe << pagamento.numero_documento.to_s.rjust(10, ' ')   # numero do documento alfanum.                X[10]       111 a 120
          detalhe << pagamento.data_vencimento.strftime('%d%m%y')     # data de vencimento                          9[06]       121 a 126
          detalhe << pagamento.formata_valor                          # valor do titulo                             9[13]       127 a 139
          detalhe << ''.rjust(3, '0')                                 # banco encarregado (zeros)                   9[03]       140 a 142
          detalhe << ''.rjust(5, '0')                                 # agencia depositaria (zeros)                 9[05]       143 a 147
          detalhe << pagamento.especie_titulo                         # especie do titulo                           9[02]       148 a 149
          detalhe << 'N'                                              # identificacao (sempre N)                    X[01]       150 a 150
          detalhe << pagamento.data_emissao.strftime('%d%m%y')        # data de emissao                             9[06]       151 a 156
          detalhe << primeira_instrucao.rjust(2, '0')                 # 1a instrucao                                9[02]       157 a 158
          detalhe << instrucao_cobranca.rjust(2, '0')                 # quantidade de dias do prazo                 9[02]       159 a 160
          detalhe << pagamento.formata_valor_mora                     # mora                                        9[13]       161 a 173
          detalhe << pagamento.formata_data_desconto                  # data desconto                               9[06]       174 a 179
          detalhe << pagamento.formata_valor_desconto                 # valor desconto                              9[13]       180 a 192
          detalhe << pagamento.formata_valor_iof                      # valor iof                                   9[13]       193 a 205
          detalhe << pagamento.formata_valor_abatimento               # valor abatimento                            9[13]       206 a 218
          detalhe << pagamento.identificacao_sacado                   # identificacao do pagador                    9[02]       219 a 220
          detalhe << pagamento.documento_sacado.to_s.rjust(14, '0')   # cpf/cnpj do pagador                         9[14]       221 a 234
          detalhe << pagamento.nome_sacado.format_size(40)            # nome do pagador                             9[40]       235 a 274
          detalhe << formata_endereco_sacado(pagamento)               # endereco do pagador                         X[40]       275 a 314
          detalhe << ''.rjust(12, ' ')                                # 1a mensagem                                 X[12]       315 a 326
          detalhe << pagamento.cep_sacado[0..4]                       # cep do pagador                              9[05]       327 a 331
          detalhe << pagamento.cep_sacado[5..7]                       # sufixo do cep do pagador                    9[03]       332 a 334
          if pagamento.nome_avalista.present? && pagamento.documento_avalista.present?
            detalhe << monta_documento_avalista(pagamento.documento_avalista)
            detalhe << ''.rjust(2, ' ')
            detalhe << pagamento.nome_avalista.format_size(43).ljust(43, '0')
          else
            detalhe << pagamento.mensagem.format_size(60)             # 2a mensagem - verificar                     X[60]       335 a 394
          end
          detalhe << sequencial.to_s.rjust(6, '0')                    # numero do registro do arquivo               9[06]       395 a 400
          detalhe
        end

        def monta_detalhe_avalista(pagamento, sequencial)
          raise Brcobranca::RemessaInvalida, pagamento if pagamento.invalid?
          detalhe = '7'                                                         # Tipo Registro              9[001]    001 - 001
          detalhe << pagamento.endereco_avalista.format_size(45).rjust(45, ' ') # Endereço Sacador/Avalista  A[045]    002 - 046
          detalhe << pagamento.cep_avalista.format_size(8).rjust(8, ' ')        # CEP                        9[008]    047 - 054
          detalhe << pagamento.cidade_avalista.format_size(20)                  # Cidade                     A[020]    055 - 074
          detalhe << pagamento.uf_avalista.format_size(2)                       # UF                         A[002]    075 - 076
          detalhe << ' '.rjust(290, ' ')                                        # BRANCO                     A[290]    077 - 366
          detalhe << carteira.to_s.rjust(3, '0')                                # Carteira                   9[003]    367 - 369
          detalhe << agencia                                                    # Agência                    9[005]    370 - 374
          detalhe << conta_corrente                                             # Conta Corrente             9[007]    375 - 381
          detalhe << digito_conta                                               # Dígito C/C                 A[001]    382 - 382
          detalhe << pagamento.nosso_numero.to_s.rjust(11, '0')                 # Nosso Número               9[011]    383 - 393
          detalhe << digito_nosso_numero(pagamento.nosso_numero).to_s           # DAC Nosso Número           A[001]    394 - 394
          detalhe << sequencial.to_s.rjust(6, '0')                              # Nº Seqüencial de Registro  9[006]    395 - 400
          detalhe
        end
      end
    end
  end
end
