# -*- encoding: utf-8 -*-
#
module Brcobranca
  module Brpagamento
    module Remessa
      module Cnab240
        class Base < Brcobranca::Brpagamento::Remessa::Base
          def initialize(campos = {})
            campos = { }.merge!(campos)
            super(campos)
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

          # Monta o registro header do arquivo
          #
          # @return [String]
          #
          def monta_header_arquivo
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
          end

          # Monta o registro header do lote
          #
          # @param nro_lote [Integer]
          #   numero do lote no arquivo (iterar a cada novo lote)
          #
          # @return [String]
          #
          def monta_header_lote(nro_lote)
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
          end

          # Monta o registro segmento A do arquivo
          #
          # @param pagamento [Brcobranca::Brpagamento::Remessa::Pagamento]
          #   objeto contendo os detalhes do boleto (valor, vencimento, sacado, etc)
          # @param nro_lote [Integer]
          #   numero do lote que o segmento esta inserido
          # @param sequencial [Integer]
          #   numero sequencial do registro no lote
          #
          # @return [String]
          #
          def monta_segmento_a(pagamento, nro_lote, sequencial)
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
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
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
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
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
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

            remittance = arquivo.join("\n").unicode_normalize(:nfkd).encode('ASCII', invalid: :replace, undef: :replace, replace: '').upcase
            remittance << "\n"
            remittance.encode(remittance.encoding, universal_newline: true).encode(remittance.encoding, crlf_newline: true)
          end


          # Numero da versao do layout do arquivo
          #
          # Este metodo deve ser sobrescrevido na classe do banco
          #
          def versao_layout_arquivo
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
          end

          # Numero da versao do layout do lote
          #
          # Este metodo deve ser sobrescrevido na classe do banco
          #
          def versao_layout_lote
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
          end

          # Nome do banco
          #
          # Este metodo deve ser sobrescrevido na classe do banco
          #
          def nome_banco
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
          end

          # Codigo do banco
          #
          # Este metodo deve ser sobrescrevido na classe do banco
          #
          def cod_banco
            raise Brcobranca::NaoImplementado, 'Sobreescreva este método na classe referente ao banco que você esta criando'
          end
        end
      end
    end
  end
end