# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Remessa
    module Cnab444
      class Paulista < Brcobranca::Remessa::Cnab444::Base
        # codigo da empresa (informado pelo Bradesco no cadastramento)
        attr_accessor :codigo_empresa
        attr_accessor :tipo_registro
        attr_accessor :coobrigacao
        attr_accessor :identificacao_ocorrencia
        attr_accessor :primeira_instrucao
        attr_accessor :segunda_instrucao
        attr_accessor :header_vendor_bank_account

        validates_presence_of :tipo_registro,
                              :coobrigacao,
                              :primeira_instrucao,
                              :segunda_instrucao, message: 'não pode estar em branco.'

        def initialize(campos = {})
          campos = {
            tipo_registro: "1",
            coobrigacao: "01",
            identificacao_ocorrencia: "01",
            primeira_instrucao: "99",
            segunda_instrucao: "9"
          }.merge!(campos)
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
          end
          ret << monta_trailer(contador + 1)

          remittance = ret.join("\n").unicode_normalize(:nfkd).encode('ASCII', invalid: :replace, undef: :replace, replace: '').upcase
          remittance << "\n"

          remittance.encode(remittance.encoding, universal_newline: true).encode(remittance.encoding, crlf_newline: true)
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
          '611'
        end

        def nome_banco
          'PAULISTA S.A.'.ljust(15, ' ')
        end

        def complemento
          "#{''.rjust(8, ' ')}MX#{sequencial_remessa}#{header_vendor_bank_account_segment}#{''.rjust(299, ' ')}"
        end

        def header_vendor_bank_account_segment
          return ''.ljust(22, ' ') if header_vendor_bank_account.nil?

          conta = header_vendor_bank_account

          "#{conta[:banco].rjust(3, ' ')}"\
          "#{conta[:agencia].rjust(5, ' ')}"\
          "#{conta[:agencia_digito].rjust(1, ' ')}"\
          "#{conta[:conta].rjust(12, ' ')}"\
          "#{conta[:conta_digito].rjust(1, ' ')}"
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
          detalhe = tipo_registro.rjust(1, "0")                                                    # Sim 9(01) 1
          detalhe << "".ljust(19, " ")                                                             # Não X(19) Branco
          detalhe << pagamento.coobrigacao.rjust(2, "0")                                           # SIM 9(02) 01 =Com Coobrigação 02 = Sem Coobrigação
          detalhe << pagamento.caracteristica_especial.rjust(2, "0")                               # Não 9(02) Preencher de acordo com o Anexo 8 do layout SRC3040 do Bacen
          detalhe << pagamento.modalidade_operacao.rjust(4, "0")                                   # Não 9(04) Preencher de acordo com o Anexo 3 do layout SRC3040 do Bacen – preencher o domínio e o subdomínio
          detalhe << pagamento.natureza_operacao.rjust(2 , "0")                                    # Não 9(02) Preencher de acordo com o Anexo 2 do layout SRC3040 do Bacen
          detalhe << pagamento.origem_recurso.rjust(4, "0")                                        # Não 9(04) Preencher de acordo com o Anexo 4 do layout SRC3040 do Bacen– preencher o domínio e o subdomínio
          detalhe << pagamento.classe_risco_operacao.ljust(2 , " ")                                # Não X(02) Preencher de acordo com o Anexo 17 do layout SRC3040 do Bacen – preencher da esquerda para direita
          detalhe << "".rjust(1, "0")                                                              # Não 9(01) Zeros
          detalhe << pagamento.uso_da_empresa.ljust(25, " ").format_size(25)                       # Sim X(25) Nº de Controle do Participante
          detalhe << "".rjust(3, "0")                                                              # Sim 9(03) Se espécie = cheque, o campo é obrigatório. Se espécie diferente de cheque preencher com 000
          detalhe << "".rjust(5, "0")                                                              # Sim 9(05) Zeros
          detalhe << pagamento.nosso_numero.to_s.rjust(11, '0').format_size(11)                    # Não 9(11) Branco
          detalhe << "".ljust(1, " ")                                                              # Não X(01) Branco nosso_numero_dv
          detalhe << pagamento.formata_valor_liquidacao(10)                                        # Não 9(10) Valor pago na liquidação/baixa do título (obrigatório na Liquidação)
          detalhe << "1".ljust(1, "0")                                                             # Não X(01) Zeros
          detalhe << "N".ljust(1, " ")                                                             # Não 9(01) Branco n = Banco não emite condicao_emissao
          detalhe << "".rjust(6, "0")                                                              # Sim 9(06) data_liquidacao DDMMAA (somente para liquidação do título)
          detalhe << "".ljust(4, " ")                                                              # Não X(04) Branco identificacao_operacao
          detalhe << "".ljust(1 , " ")                                                             # Não X(01) Branco indicador_rateio_credito
          detalhe << "2".rjust(1, "0")                                                             # Não 9(01) Branco enderecamento_debito_automatico 1 = Sim; 2 = Não
          detalhe << "".rjust(2, " ")                                                              # Não X(02) Branco
          detalhe << identificacao_ocorrencia.rjust(2, "0")                                        # Sim 9(02) Vide seção 4.1 números 23 do documento
          detalhe << pagamento.numero_documento.ljust(10, " ").format_size(10)                     # Sim X(10) Nº do Documento
          detalhe << pagamento.data_vencimento.strftime('%d%m%y').rjust(6, "0")                    # Sim 9(06) DDMMAA
          detalhe << pagamento.formata_valor                                                       # Sim 9(13) Valor do Título (preencher sem ponto e sem vírgula)
          detalhe << "".rjust(3, "0")                                                              # Não 9(03) Nº do Banco na Câmara de Compensação ou 000
          detalhe << "".rjust(5, "0")                                                              # Não 9(05) Código da Agência Depositária ou 00000
          detalhe << pagamento.especie_titulo.rjust(2 , "0")                                       # Sim 9(02) Espécie de Título
          detalhe << "N".ljust(1, " ")                                                             # Não X(01) Branco identificacao
          detalhe << pagamento.data_emissao.strftime('%d%m%y').rjust(6, "0")                       # Sim 9(06) DDMMAA
          detalhe << primeira_instrucao.rjust(2, "0")                                              # Não 9(02) 1ª instrução
          detalhe << segunda_instrucao.rjust(1, "0")                                               # Não 9(01) 2ª instrução
          detalhe << pagamento.identificacao_cedente(pagamento.documento_cedente).ljust(2, " ")    # SIM X(02) 01 - Pessoa Física;  02 - Pessoa Jurídica;
          detalhe << "".rjust(12, "0")                                                             # Não X(12) Zeros
          detalhe << pagamento.numero_termo_cessao.ljust(19, " ").format_size(19)                  # Sim X(19) Conforme número enviado pela consultoria (campos alfa-numéricos)
          detalhe << pagamento.formata_valor_aquisicao                                             # Sim 9(13) Valor da parcela na data que foi cedida
          detalhe << pagamento.formata_valor_abatimento                                            # Não 9(13) Valor do Abatimento a ser concedido na instrução
          detalhe << pagamento.identificacao_sacado(pagamento.documento_sacado).rjust(2, "0")      # Sim 9(02) 01-CPF 02-CNPJ
          detalhe << pagamento.documento_sacado.rjust(14, "0")                                     # Sim 9(14) CNPJ/CPF
          detalhe << pagamento.nome_sacado.ljust(40, " ").format_size(40)                          # Sim X(40) Nome do Sacado
          detalhe << pagamento.formata_endereco_sacado(pagamento).ljust(40, " ").format_size(40)   # Sim X(40) Endereço Completo
          detalhe << pagamento.n_nota_fiscal.to_s.rjust(9, "0").format_size(9)                     # Sim X(09) Numero da Nota Fiscal da Duplicata
          detalhe << pagamento.n_serie_nota_fiscal.to_s.ljust(3, " ")                              # Não X(03) Numero da Série da Nota Fiscal da Duplicata
          detalhe << pagamento.cep_sacado.rjust(8, "0")                                            # Sim 9(08) CEP
          # detalhe << cedente.ljust(60, " ")                                                      # Sim X(60) Cedente
          detalhe << pagamento.nome_cedente.ljust(46, " ").format_size(46)                         # Sim X(46) Nome do Cedente
          detalhe << pagamento.documento_cedente.ljust(14, " ")                                    # Sim X(14) CNPJ do Cedente
          detalhe << pagamento.chave_nota.to_s.ljust(44, " ")                                      # Sim X(44) Chave da Nota Eletrônica
          detalhe << sequencial.to_s.rjust(6, "0")                                                 # Sim 9(06) Nº Seqüencial do Registro
          detalhe
        end
      end
    end
  end
end
