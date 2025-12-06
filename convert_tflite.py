import subprocess
import sys
import os

print("=== Conversion du modèle TFLite vers TensorFlow.js ===")

# Vérifier si tensorflowjs est installé
try:
    import tensorflowjs as tfjs
    print("✅ tensorflowjs est déjà installé")
except ImportError:
    print("⚠️ Installation de tensorflowjs...")
    subprocess.check_call([sys.executable, "-m", "pip", "install", "tensorflowjs", "--user"])

# Chemins
input_model = "assets/model/model.tflite"
output_dir = "web/model"

print(f"\n📁 Modèle d'entrée: {input_model}")
print(f"📁 Dossier de sortie: {output_dir}")

# Vérifier si le modèle existe
if not os.path.exists(input_model):
    print(f"❌ ERREUR: Le fichier {input_model} n'existe pas!")
    print("\nStructure attendue:")
    print("  smart_app_elbakay_g8/")
    print("  ├── assets/")
    print("  │   └── model/")
    print("  │       ├── model.tflite    ← Votre modèle")
    print("  │       └── label.txt       ← Vos labels")
    sys.exit(1)

# Créer le dossier de sortie
os.makedirs(output_dir, exist_ok=True)

# Copier les labels
labels_src = "assets/model/label.txt"
labels_dst = os.path.join(output_dir, "labels.txt")

if os.path.exists(labels_src):
    import shutil
    shutil.copy(labels_src, labels_dst)
    print(f"✅ Labels copiés: {labels_dst}")
    
    # Afficher les labels
    with open(labels_dst, 'r', encoding='utf-8') as f:
        labels = [line.strip() for line in f if line.strip()]
    print(f"   Labels trouvés: {labels}")
else:
    print("⚠️ Fichier label.txt non trouvé, création d'un fichier par défaut")
    with open(labels_dst, 'w', encoding='utf-8') as f:
        f.write("Apple\nBanana\nOrange\n")

# Convertir le modèle
print("\n🔄 Conversion en cours...")
try:
    # Commande de conversion
    cmd = [
        sys.executable, "-m", "tensorflowjs.converters.converter",
        "--input_format=tf_lite",
        "--output_format=tfjs_graph_model",
        "--quantization_bytes=2",  # Réduire la taille
        "--weight_shard_size_bytes=4194304",  # 4MB par shard
        input_model,
        output_dir
    ]
    
    print("Commande:", " ".join(cmd))
    result = subprocess.run(cmd, capture_output=True, text=True)
    
    if result.returncode == 0:
        print("✅ Conversion réussie!")
        
        # Lister les fichiers générés
        print("\n📄 Fichiers générés:")
        for file in os.listdir(output_dir):
            filepath = os.path.join(output_dir, file)
            size = os.path.getsize(filepath)
            print(f"  - {file} ({size:,} octets)")
    else:
        print("❌ Erreur pendant la conversion:")
        print(result.stderr)
        
except Exception as e:
    print(f"❌ Erreur: {e}")

print("\n=== Conversion terminée ===")
input("Appuyez sur Entrée pour quitter...")