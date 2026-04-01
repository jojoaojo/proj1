#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
ANALISADOR COMPLETO DE PDF
Extrai texto, imagens, e fornece análise visual usando OCR se necessário
"""

import fitz  # PyMuPDF
import sys
import os
from pathlib import Path

def analyze_pdf_complete(pdf_path, output_dir="pdf_analysis"):
    """
    Análise completa de PDF: texto + imagens + metadados
    """
    print("═" * 70)
    print("  ANÁLISE COMPLETA DE PDF")
    print("═" * 70)
    
    # Criar diretório de saída
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    # Abrir PDF
    doc = fitz.open(pdf_path)
    
    # Metadados
    print(f"\n📄 ARQUIVO: {pdf_path}")
    print(f"📊 Total de páginas: {len(doc)}")
    print(f"📋 Metadados:")
    for key, value in doc.metadata.items():
        if value:
            print(f"   • {key}: {value}")
    
    # Arquivo de texto consolidado
    text_output = output_path / "texto_completo.txt"
    images_dir = output_path / "images"
    images_dir.mkdir(exist_ok=True)
    
    total_images = 0
    pages_with_images = []
    
    with open(text_output, 'w', encoding='utf-8') as f:
        f.write(f"ANÁLISE COMPLETA DO PDF: {pdf_path}\n")
        f.write("=" * 70 + "\n\n")
        
        for page_num in range(len(doc)):
            page = doc[page_num]
            
            # Extrair texto
            text = page.get_text()
            
            f.write(f"\n{'=' * 70}\n")
            f.write(f"PÁGINA {page_num + 1}\n")
            f.write(f"{'=' * 70}\n\n")
            f.write(text)
            
            # Extrair imagens
            images = page.get_images()
            
            if images:
                pages_with_images.append(page_num + 1)
                total_images += len(images)
                
                f.write(f"\n[!] Esta página contém {len(images)} imagem(ns)\n")
                
                for img_idx, img in enumerate(images):
                    try:
                        xref = img[0]
                        base_image = doc.extract_image(xref)
                        image_bytes = base_image['image']
                        image_ext = base_image['ext']
                        
                        img_filename = f"page{page_num + 1:03d}_img{img_idx + 1}.{image_ext}"
                        img_path = images_dir / img_filename
                        
                        with open(img_path, 'wb') as img_file:
                            img_file.write(image_bytes)
                        
                        f.write(f"   → Imagem salva: {img_filename}\n")
                        
                    except Exception as e:
                        f.write(f"   ✗ Erro ao extrair imagem {img_idx + 1}: {e}\n")
    
    doc.close()
    
    # Resumo final
    print(f"\n{'═' * 70}")
    print("  RESUMO DA ANÁLISE")
    print(f"{'═' * 70}")
    print(f"\n✅ Texto extraído: {text_output}")
    print(f"✅ Total de imagens encontradas: {total_images}")
    
    if pages_with_images:
        print(f"✅ Páginas com imagens: {pages_with_images}")
        print(f"✅ Imagens salvas em: {images_dir}")
    else:
        print(f"ℹ️  Nenhuma imagem encontrada no PDF")
    
    print(f"\n📁 Todos os arquivos salvos em: {output_path.absolute()}")
    print(f"{'═' * 70}\n")
    
    return {
        'total_pages': len(doc),
        'total_images': total_images,
        'pages_with_images': pages_with_images,
        'text_file': str(text_output),
        'images_dir': str(images_dir)
    }


def analyze_pdf_section(pdf_path, start_page, end_page, output_dir="pdf_analysis_section"):
    """
    Análise de uma seção específica do PDF
    """
    print(f"\n📖 Analisando páginas {start_page} a {end_page}...\n")
    
    output_path = Path(output_dir)
    output_path.mkdir(exist_ok=True)
    
    doc = fitz.open(pdf_path)
    
    text_output = output_path / f"secao_p{start_page}-{end_page}.txt"
    images_dir = output_path / "images"
    images_dir.mkdir(exist_ok=True)
    
    with open(text_output, 'w', encoding='utf-8') as f:
        for page_num in range(start_page - 1, min(end_page, len(doc))):
            page = doc[page_num]
            text = page.get_text()
            images = page.get_images()
            
            f.write(f"\n{'─' * 60}\n")
            f.write(f"PÁGINA {page_num + 1}\n")
            f.write(f"{'─' * 60}\n\n")
            f.write(text)
            
            if images:
                f.write(f"\n[!] {len(images)} imagem(ns) nesta página\n")
                
                for img_idx, img in enumerate(images):
                    try:
                        xref = img[0]
                        base_image = doc.extract_image(xref)
                        image_bytes = base_image['image']
                        image_ext = base_image['ext']
                        
                        img_filename = f"page{page_num + 1:03d}_img{img_idx + 1}.{image_ext}"
                        img_path = images_dir / img_filename
                        
                        with open(img_path, 'wb') as img_file:
                            img_file.write(image_bytes)
                        
                        f.write(f"   → {img_filename}\n")
                    except:
                        pass
    
    doc.close()
    
    print(f"✅ Seção extraída: {text_output}")
    print(f"✅ Imagens em: {images_dir}\n")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Uso: python analyze_pdf.py <caminho_do_pdf> [página_início] [página_fim]")
        print("\nExemplos:")
        print("  python analyze_pdf.py lab1.pdf                    # Analisa todo o PDF")
        print("  python analyze_pdf.py lab1.pdf 24 35              # Analisa páginas 24-35")
        sys.exit(1)
    
    pdf_path = sys.argv[1]
    
    if not os.path.exists(pdf_path):
        print(f"❌ Arquivo não encontrado: {pdf_path}")
        sys.exit(1)
    
    # Se especificou intervalo de páginas
    if len(sys.argv) >= 4:
        start_page = int(sys.argv[2])
        end_page = int(sys.argv[3])
        analyze_pdf_section(pdf_path, start_page, end_page)
    else:
        # Análise completa
        analyze_pdf_complete(pdf_path)
