import brut.androlib.smali.SmaliBuilder;
import com.android.tools.smali.dexlib2.Opcodes;
import com.android.tools.smali.dexlib2.writer.builder.DexBuilder;
import com.android.tools.smali.dexlib2.writer.io.FileDataStore;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.stream.Stream;

class AssembleDex {
    public static void main(String[] args) throws Exception {
        int api = Integer.parseInt(args[2]);
        DexBuilder dex = new DexBuilder(new Opcodes(api));
        SmaliBuilder assembler = new SmaliBuilder(api);
        try (Stream<Path> paths = Files.walk(Path.of(args[0]))) {
            for (Path path : paths.filter(p -> p.toString().endsWith(".smali")).sorted().toList()) {
                if (!assembler.buildFile(path.toFile(), dex)) {
                    throw new IllegalStateException("Could not assemble " + path);
                }
            }
        }
        FileDataStore output = new FileDataStore(Path.of(args[1]).toFile());
        try { dex.writeTo(output); } finally { output.raf.close(); }
    }
}
